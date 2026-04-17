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
    var translateToEnglish: Bool {
        didSet { UserDefaults.standard.set(translateToEnglish, forKey: "translateToEnglish") }
    }
    // "auto" = no conversion, "simplified" = 繁→简, "traditional" = 简→繁
    var chineseVariant: String {
        didSet { UserDefaults.standard.set(chineseVariant, forKey: "chineseVariant") }
    }
    var autoPasteEnabled: Bool {
        didSet { UserDefaults.standard.set(autoPasteEnabled, forKey: "autoPasteEnabled") }
    }
    var uiLanguage: String {
        didSet { UserDefaults.standard.set(uiLanguage, forKey: "uiLanguage") }
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
                owLog("[Murmur] Launch at login error: \(error)")
            }
        }
    }

    // MARK: - Runtime State

    var isFirstLaunch: Bool = !UserDefaults.standard.bool(forKey: "hasLaunched")
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
        translateToEnglish = defaults.object(forKey: "translateToEnglish") as? Bool ?? false
        chineseVariant = defaults.string(forKey: "chineseVariant") ?? "simplified"
        autoPasteEnabled = defaults.object(forKey: "autoPasteEnabled") as? Bool ?? true
        uiLanguage = defaults.string(forKey: "uiLanguage") ?? "zh"
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: - Setup

    func setup() async {
        owLog("[Murmur] Setting up...")
        audioEngine = AudioEngine()
        transcriber = WhisperTranscriber()
        llmCleanup = LLMCleanup()
        textInjector = TextInjector()
        flowBarController = FlowBarController(appState: self)

        // Clean up any incomplete model downloads from previous crashes
        transcriber?.cleanIncompleteDownloads()

        owLog("[Murmur] Flow bar ready (hidden until recording)")

        // Request mic permission
        microphoneGranted = await audioEngine?.requestPermission() ?? false
        owLog("[Murmur] Microphone permission: \(microphoneGranted)")

        // Check accessibility
        accessibilityGranted = GlobalHotkey.checkAccessibility(prompt: true)
        owLog("[Murmur] Accessibility: \(accessibilityGranted)")

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
        owLog("[Murmur] Hotkey registered (Right Option)")

        // Load Whisper model
        owLog("[Murmur] Loading model: \(whisperModel)...")
        await loadModel()
        owLog("[Murmur] Model loaded: \(modelLoaded)")

        // Check Ollama availability
        ollamaAvailable = await LLMCleanup.checkAvailability()
        owLog("[Murmur] Ollama available: \(ollamaAvailable)")

        // Setup reminders
        reminderManager = ReminderManager.shared
        let notifGranted = await reminderManager?.requestPermission() ?? false
        owLog("[Murmur] Notification permission: \(notifGranted)")
        owLog("[Murmur] Ready!")

        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
        }
    }

    func dismissOnboarding() {
        isFirstLaunch = false
    }

    private let modelFallbackOrder = ["large-v3_turbo", "large-v3", "small", "base", "tiny"]

    var failedModelName: String?  // Non-nil when a model failed and needs user action

    func loadModel() async {
        modelLoaded = false
        modelLoading = true
        modelLoadProgress = 0
        lastError = nil
        failedModelName = nil
        let wasDownloading = !(transcriber?.isModelDownloaded(name: whisperModel) ?? false)
        modelIsDownloading = wasDownloading
        owLog("[Murmur] Loading model: \(whisperModel) (download needed: \(wasDownloading))...")
        do {
            try await transcriber?.loadModel(name: whisperModel) { [weak self] progress in
                Task { @MainActor in
                    self?.modelLoadProgress = progress
                }
            }
            modelLoaded = true
            modelLoading = false
            lastError = nil
            refreshDownloadedModels()
            owLog("[Murmur] Model loaded: \(modelLoaded)")

            // Notify user if they're not looking at the menu
            if wasDownloading {
                sendNotification(
                    title: "Murmur",
                    body: uiLanguage == "zh"
                        ? "模型 \(whisperModel) 已就绪，可以开始使用"
                        : "Model \(whisperModel) is ready to use"
                )
                playSound("Glass", volume: 0.2)
            }
        } catch {
            owLog("[Murmur] Model load failed: \(error)")
            modelLoading = false

            // Delete the broken model
            transcriber?.deleteModel(name: whisperModel)
            refreshDownloadedModels()

            // Don't auto-fallback — let user decide
            failedModelName = whisperModel
            lastError = uiLanguage == "zh"
                ? "\(whisperModel) 下载不完整或已损坏"
                : "\(whisperModel) is incomplete or corrupted"
        }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    /// Find the largest available downloaded model as fallback
    func findFallbackModel() -> String? {
        for name in modelFallbackOrder {
            if name != whisperModel && (transcriber?.isModelDownloaded(name: name) ?? false) {
                return name
            }
        }
        return nil
    }

    /// Retry: delete corrupted model and re-download
    func retryModelDownload() {
        transcriber?.deleteModel(name: whisperModel)
        lastError = nil
        refreshDownloadedModels()
        Task { await loadModel() }
    }

    /// Delete a specific model
    func deleteWhisperModel(name: String) {
        transcriber?.deleteModel(name: name)
        refreshDownloadedModels()
        if name == whisperModel {
            modelLoaded = false
        }
    }

    /// Open model directory in Finder
    func openModelDirectory() {
        let url = WhisperTranscriber.modelBaseURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }

    // MARK: - Recording Flow

    func startRecording() {
        guard recordingState == .idle else { return }
        guard modelLoaded else {
            owLog("[Murmur] Cannot record — model not loaded yet")
            playSound("Basso", volume: 0.3)
            // Show notification to user
            let content = UNMutableNotificationContent()
            content.title = "Murmur"
            content.body = uiLanguage == "zh" ? "模型未加载，请在设置中选择并下载模型" : "Model not loaded. Please select and download a model in settings."
            let request = UNNotificationRequest(identifier: "no-model", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
            return
        }

        // Save the currently focused app BEFORE we start recording,
        // so we can re-activate it when pasting the transcription
        targetApp = NSWorkspace.shared.frontmostApplication
        owLog("[Murmur] Target app: \(targetApp?.localizedName ?? "unknown")")

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
        owLog("[Murmur] Transcribing...")

        recordingTimer?.invalidate()
        recordingTimer = nil

        guard let audioData = audioEngine?.stopRecording() else {
            owLog("[Murmur] No audio captured")
            recordingState = .idle
            hideFlowBarAfterDelay(0.3)
            return
        }

        guard audioData.count > 4800 else {
            owLog("[Murmur] Audio too short (\(audioData.count) samples)")
            recordingState = .idle
            hideFlowBarAfterDelay(0.3)
            return
        }

        // Silent detection: skip if average volume too low
        let rms = sqrt(audioData.map { $0 * $0 }.reduce(0, +) / Float(audioData.count))
        if rms < 0.005 {
            owLog("[Murmur] Audio too quiet (rms=\(rms)), skipping")
            recordingState = .idle
            hideFlowBarAfterDelay(0.3)
            return
        }

        Task {
            do {
                var text = try await transcriber?.transcribe(
                    audioData: audioData,
                    language: language,
                    translateToEnglish: translateToEnglish
                ) ?? ""

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty,
                      !trimmed.hasPrefix("[BLANK"),
                      !trimmed.hasPrefix("(BLANK") else {
                    owLog("[Murmur] Empty/blank transcription, skipping")
                    recordingState = .idle
                    hideFlowBarAfterDelay(0.3)
                    return
                }

                owLog("[Murmur] Raw: \(text)")

                // Chinese variant conversion (zero-cost, no LLM needed)
                if (language == "zh" || language == "") && chineseVariant != "auto" {
                    text = convertChineseVariant(text, to: chineseVariant)
                }

                // Check raw text for reminder intent BEFORE LLM cleanup can alter it
                let isReminderCommand = ReminderManager.isReminder(text)

                if isReminderCommand {
                    owLog("[Murmur] Reminder detected: \(text)")
                    lastTranscription = text
                    if ollamaAvailable {
                        let _ = await reminderManager?.handleReminder(text: text)
                    } else {
                        owLog("[Murmur] Cannot set reminder — Ollama not available")
                    }
                } else {
                    if llmCleanupEnabled && ollamaAvailable {
                        text = await llmCleanup?.cleanup(text: text, model: llmModel) ?? text
                        owLog("[Murmur] Cleaned: \(text)")
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
                owLog("[Murmur] Error: \(error)")
                lastError = error.localizedDescription
                playSound("Sosumi", volume: 0.2)
            }

            recordingState = .idle
            hideFlowBarAfterDelay()
        }
    }

    private func hideFlowBarAfterDelay(_ delay: TimeInterval = 1.5) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            if self?.recordingState == .idle {
                self?.flowBarController?.hide()
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

    // MARK: - Chinese Variant

    private func convertChineseVariant(_ text: String, to variant: String) -> String {
        let mutable = NSMutableString(string: text)
        if variant == "simplified" {
            CFStringTransform(mutable, nil, "Traditional-Simplified" as CFString, false)
        } else if variant == "traditional" {
            CFStringTransform(mutable, nil, "Simplified-Traditional" as CFString, false)
        }
        return mutable as String
    }

    // MARK: - Sound

    private func playSound(_ name: String, volume: Float) {
        guard let sound = NSSound(named: NSSound.Name(name)) else { return }
        sound.volume = volume
        sound.play()
    }
}
