import SwiftUI
import Observation
import AVFoundation
import ApplicationServices
import ServiceManagement
import AppKit
import UserNotifications

@Observable
@MainActor
final class AppState {

    static let shared = AppState()

    // MARK: - Recording State

    enum RecordingState: Sendable {
        case idle, recording, transcribing
    }

    var recordingState: RecordingState = .idle

    // MARK: - Settings (persisted via UserDefaults)

    var whisperModel: String {
        didSet { UserDefaults.standard.set(whisperModel, forKey: "whisperModel") }
    }
    var language: String {
        didSet { UserDefaults.standard.set(language, forKey: "language") }
    }
    var llmCleanupEnabled: Bool {
        didSet { UserDefaults.standard.set(llmCleanupEnabled, forKey: "llmCleanupEnabled") }
    }
    var llmModel: String {
        didSet { UserDefaults.standard.set(llmModel, forKey: "llmModel") }
    }
    var flowBarEnabled: Bool {
        didSet { UserDefaults.standard.set(flowBarEnabled, forKey: "flowBarEnabled") }
    }
    var flowBarTheme: String {
        didSet { UserDefaults.standard.set(flowBarTheme, forKey: "flowBarTheme") }
    }
    var autoPasteEnabled: Bool {
        didSet { UserDefaults.standard.set(autoPasteEnabled, forKey: "autoPasteEnabled") }
    }
    var launchAtLogin: Bool {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                owLog("[OpenWhisper] Launch at login error: \(error)")
            }
        }
    }

    // MARK: - Runtime State

    var audioLevel: Float = 0.0
    var recordingDuration: TimeInterval = 0.0
    var ollamaAvailable: Bool = false
    var modelLoaded: Bool = false
    var modelLoading: Bool = false
    var modelLoadProgress: Double = 0.0
    var modelIsDownloading: Bool = false
    var lastTranscription: String = ""
    var lastError: String?
    var accessibilityGranted: Bool = false
    var microphoneGranted: Bool = false
    var downloadedWhisperModels: Set<String> = []
    var installedLLMModels: Set<String> = []

    // MARK: - Components

    private var audioEngine: AudioEngine?
    private var transcriber: WhisperTranscriber?
    private var llmCleanup: LLMCleanup?
    private var textInjector: TextInjector?
    private var hotkey: GlobalHotkey?
    private var flowBarController: FlowBarController?
    private var reminderManager: ReminderManager?
    private var recordingTimer: Timer?
    private var targetApp: NSRunningApplication?

    // MARK: - Computed

    var menuBarIcon: String {
        switch recordingState {
        case .idle: "mic.fill"
        case .recording: "record.circle.fill"
        case .transcribing: "ellipsis.circle.fill"
        }
    }

    var menuBarIconColor: Color {
        switch recordingState {
        case .idle: .gray
        case .recording: .red
        case .transcribing: .orange
        }
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        whisperModel = defaults.string(forKey: "whisperModel") ?? "small"
        language = defaults.string(forKey: "language") ?? "zh"
        llmCleanupEnabled = defaults.object(forKey: "llmCleanupEnabled") as? Bool ?? true
        llmModel = defaults.string(forKey: "llmModel") ?? "qwen2.5:1.5b"
        flowBarEnabled = defaults.object(forKey: "flowBarEnabled") as? Bool ?? true
        flowBarTheme = defaults.string(forKey: "flowBarTheme") ?? "voiceFirst"
        autoPasteEnabled = defaults.object(forKey: "autoPasteEnabled") as? Bool ?? true
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: - Setup

    func setup() async {
        owLog("[OpenWhisper] Setting up...")
        audioEngine = AudioEngine()
        transcriber = WhisperTranscriber()
        llmCleanup = LLMCleanup()
        textInjector = TextInjector()
        flowBarController = FlowBarController(appState: self)

        // Flow bar starts hidden — only shows during recording/transcribing
        owLog("[OpenWhisper] Flow bar ready (hidden until recording)")

        // Request mic permission
        microphoneGranted = await audioEngine?.requestPermission() ?? false
        owLog("[OpenWhisper] Microphone permission: \(microphoneGranted)")

        // Check accessibility
        accessibilityGranted = GlobalHotkey.checkAccessibility(prompt: true)
        owLog("[OpenWhisper] Accessibility: \(accessibilityGranted)")

        // Register global hotkey
        hotkey = GlobalHotkey(
            onPress: { [weak self] in
                Task { @MainActor in self?.startRecording() }
            },
            onRelease: { [weak self] in
                Task { @MainActor in self?.stopRecording() }
            }
        )
        hotkey?.register()
        owLog("[OpenWhisper] Hotkey registered (Right Option)")

        // Load Whisper model
        owLog("[OpenWhisper] Loading model: \(whisperModel)...")
        await loadModel()
        owLog("[OpenWhisper] Model loaded: \(modelLoaded)")

        // Check Ollama availability
        ollamaAvailable = await LLMCleanup.checkAvailability()
        owLog("[OpenWhisper] Ollama available: \(ollamaAvailable)")

        // Setup reminders
        reminderManager = ReminderManager.shared
        let notifGranted = await reminderManager?.requestPermission() ?? false
        owLog("[OpenWhisper] Notification permission: \(notifGranted)")
        owLog("[OpenWhisper] Ready!")
    }

    func loadModel() async {
        modelLoaded = false
        modelLoading = true
        modelLoadProgress = 0
        modelIsDownloading = !(transcriber?.isModelDownloaded(name: whisperModel) ?? false)
        owLog("[OpenWhisper] Loading model: \(whisperModel) (download needed: \(modelIsDownloading))...")
        do {
            try await transcriber?.loadModel(name: whisperModel) { [weak self] progress in
                Task { @MainActor in
                    self?.modelLoadProgress = progress
                }
            }
            modelLoaded = true
            modelLoading = false
            owLog("[OpenWhisper] Model loaded: \(modelLoaded)")
        } catch {
            modelLoading = false
            lastError = "Failed to load model: \(error.localizedDescription)"
            owLog("[OpenWhisper] Model load failed: \(error)")
        }
    }

    // MARK: - Recording Flow

    func startRecording() {
        guard recordingState == .idle else { return }
        guard modelLoaded else {
            owLog("[OpenWhisper] Cannot record — model not loaded yet")
            return
        }

        // Save the currently focused app BEFORE we start recording,
        // so we can re-activate it when pasting the transcription
        targetApp = NSWorkspace.shared.frontmostApplication
        owLog("[OpenWhisper] Target app: \(targetApp?.localizedName ?? "unknown")")

        recordingState = .recording
        recordingDuration = 0
        audioLevel = 0
        lastError = nil
        playSound("Tink", volume: 0.3)

        // Show flow bar when recording starts
        if flowBarEnabled {
            flowBarController?.show()
        }

        audioEngine?.startRecording { [weak self] level in
            Task { @MainActor in
                self?.audioLevel = level
            }
        }

        // Start duration timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 0.1
            }
        }

    }

    func stopRecording() {
        guard recordingState == .recording else { return }
        recordingState = .transcribing
        playSound("Pop", volume: 0.2)
        owLog("[OpenWhisper] Transcribing...")

        recordingTimer?.invalidate()
        recordingTimer = nil

        guard let audioData = audioEngine?.stopRecording() else {
            owLog("[OpenWhisper] No audio captured")
            recordingState = .idle
            return
        }

        guard audioData.count > 4800 else {
            owLog("[OpenWhisper] Audio too short (\(audioData.count) samples)")
            recordingState = .idle
            return
        }

        Task {
            do {
                var text = try await transcriber?.transcribe(
                    audioData: audioData,
                    language: language
                ) ?? ""

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty,
                      !trimmed.hasPrefix("[BLANK"),
                      !trimmed.hasPrefix("(BLANK") else {
                    owLog("[OpenWhisper] Empty/blank transcription, skipping")
                    recordingState = .idle
                    return
                }

                owLog("[OpenWhisper] Raw: \(text)")

                // Check raw text for reminder intent BEFORE LLM cleanup can alter it
                let isReminderCommand = ReminderManager.isReminder(text)

                if isReminderCommand {
                    owLog("[OpenWhisper] Reminder detected: \(text)")
                    lastTranscription = text
                    if ollamaAvailable {
                        let _ = await reminderManager?.handleReminder(text: text)
                    } else {
                        owLog("[OpenWhisper] Cannot set reminder — Ollama not available")
                    }
                } else {
                    if llmCleanupEnabled && ollamaAvailable {
                        text = await llmCleanup?.cleanup(text: text, model: llmModel) ?? text
                        owLog("[OpenWhisper] Cleaned: \(text)")
                    }

                    lastTranscription = text

                    if autoPasteEnabled {
                        textInjector?.pasteText(text, targetApp: targetApp)
                    } else {
                        textInjector?.copyToClipboard(text)
                    }
                    playSound("Glass", volume: 0.15)
                }
            } catch {
                owLog("[OpenWhisper] Error: \(error)")
                lastError = error.localizedDescription
                playSound("Sosumi", volume: 0.2)
            }

            recordingState = .idle

            // Hide flow bar after a brief delay (let done animation finish)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.recordingState == .idle {
                    self?.flowBarController?.hide()
                }
            }
        }
    }

    // MARK: - Refresh

    func refreshPermissions() {
        accessibilityGranted = GlobalHotkey.checkAccessibility(prompt: false)
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        microphoneGranted = (status == .authorized)
    }

    func refreshOllamaStatus() async {
        ollamaAvailable = await LLMCleanup.checkAvailability()
    }

    func refreshDownloadedModels() {
        let whisperModels = ["tiny", "base", "small", "small.en", "large-v3", "large-v3_turbo"]
        var downloaded = Set<String>()
        for name in whisperModels {
            if transcriber?.isModelDownloaded(name: name) == true {
                downloaded.insert(name)
            }
        }
        downloadedWhisperModels = downloaded
    }

    func refreshInstalledLLMModels() async {
        guard let url = URL(string: "http://localhost:11434/api/tags") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                var names = Set<String>()
                for model in models {
                    if let name = model["name"] as? String {
                        names.insert(name)
                    }
                }
                installedLLMModels = names
            }
        } catch {}
    }

    // MARK: - Sound

    private func playSound(_ name: String, volume: Float) {
        guard let sound = NSSound(named: NSSound.Name(name)) else { return }
        sound.volume = volume
        sound.play()
    }
}
