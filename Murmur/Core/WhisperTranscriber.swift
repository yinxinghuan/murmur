import WhisperKit
import Foundation

final class WhisperTranscriber: @unchecked Sendable {
    private var whisperKit: WhisperKit?

    /// Base directory for all models
    static var modelBaseURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Murmur/Models")
    }

    /// Directory for a specific model
    static func modelURL(name: String) -> URL {
        modelBaseURL.appendingPathComponent("models/argmaxinc/whisperkit-coreml/openai_whisper-\(name)")
    }

    /// Check if a model is fully downloaded (all required files + weights present)
    func isModelDownloaded(name: String) -> Bool {
        let localModel = Self.modelURL(name: name)
        guard FileManager.default.fileExists(atPath: localModel.path) else { return false }
        let requiredDirs = ["MelSpectrogram.mlmodelc", "AudioEncoder.mlmodelc", "TextDecoder.mlmodelc"]
        for dir in requiredDirs {
            let dirPath = localModel.appendingPathComponent(dir)
            guard FileManager.default.fileExists(atPath: dirPath.path) else { return false }
            // Check weights file exists (this is what actually fails when download is interrupted)
            let weightsDir = dirPath.appendingPathComponent("weights")
            if FileManager.default.fileExists(atPath: weightsDir.path) {
                let weightBin = weightsDir.appendingPathComponent("weight.bin")
                if !FileManager.default.fileExists(atPath: weightBin.path) {
                    return false
                }
            }
            // Also check coremldata.bin (older format)
            let coremlBin = dirPath.appendingPathComponent("coremldata.bin")
            let modelMil = dirPath.appendingPathComponent("model.mil")
            if !FileManager.default.fileExists(atPath: coremlBin.path) &&
               !FileManager.default.fileExists(atPath: modelMil.path) {
                return false
            }
        }
        return true
    }

    /// Delete a downloaded model
    func deleteModel(name: String) {
        try? FileManager.default.removeItem(at: Self.modelURL(name: name))
    }

    /// Clean up incomplete/corrupted model downloads
    func cleanIncompleteDownloads() {
        let coremlDir = Self.modelBaseURL.appendingPathComponent("models/argmaxinc/whisperkit-coreml")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: coremlDir,
            includingPropertiesForKeys: nil
        ) else { return }

        let requiredFiles = ["MelSpectrogram.mlmodelc", "AudioEncoder.mlmodelc", "TextDecoder.mlmodelc"]
        for dir in contents where dir.hasDirectoryPath {
            let complete = requiredFiles.allSatisfy {
                FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path)
            }
            if !complete {
                owLog("[Whisper] Removing incomplete model: \(dir.lastPathComponent)")
                try? FileManager.default.removeItem(at: dir)
            }
        }
    }

    enum LoadPhase: String { case download, compile }

    /// Load a Whisper model by name
    func loadModel(name: String, progress: @escaping @Sendable (Double) -> Void, phase: @escaping @Sendable (LoadPhase) -> Void = { _ in }) async throws {
        let modelBase = Self.modelBaseURL
        try FileManager.default.createDirectory(at: modelBase, withIntermediateDirectories: true)

        // Create README if not exists
        let readmePath = modelBase.appendingPathComponent("README.txt")
        if !FileManager.default.fileExists(atPath: readmePath.path) {
            let readme = """
            Murmur — Voice Model Directory
            ==============================

            This folder contains WhisperKit CoreML models used by Murmur.
            Models are downloaded automatically from HuggingFace (argmaxinc/whisperkit-coreml).

            Supported models:
              - openai_whisper-tiny       (39 MB)
              - openai_whisper-base       (140 MB)
              - openai_whisper-small      (460 MB)
              - openai_whisper-small.en   (460 MB, English only)
              - openai_whisper-large-v3_turbo (1.6 GB)
              - openai_whisper-large-v3   (3 GB)

            To manually add a model, place the complete WhisperKit CoreML model folder
            (containing MelSpectrogram.mlmodelc, AudioEncoder.mlmodelc, TextDecoder.mlmodelc, etc.)
            under: models/argmaxinc/whisperkit-coreml/openai_whisper-{name}/

            Models can be downloaded from:
            https://huggingface.co/argmaxinc/whisperkit-coreml

            Do NOT delete this folder while Murmur is running.
            """
            try? readme.write(to: readmePath, atomically: true, encoding: .utf8)
        }

        let localModel = Self.modelURL(name: name)
        let modelFolder: URL

        if isModelDownloaded(name: name) {
            owLog("[Whisper] Model found locally: openai_whisper-\(name)")
            modelFolder = localModel
        } else {
            phase(.download)
            // Clean any partial download first
            if FileManager.default.fileExists(atPath: localModel.path) {
                owLog("[Whisper] Removing incomplete model before re-download")
                try? FileManager.default.removeItem(at: localModel)
            }

            owLog("[Whisper] Downloading model: openai_whisper-\(name)...")
            modelFolder = try await WhisperKit.download(
                variant: "openai_whisper-\(name)",
                downloadBase: modelBase
            ) { downloadProgress in
                progress(downloadProgress.fractionCompleted)
            }
            owLog("[Whisper] Download complete at: \(modelFolder.path)")
        }

        // Compile CoreML model — can take 30-90s for large models
        phase(.compile)
        progress(0)
        owLog("[Whisper] Compiling CoreML model (this may take a while for large models)...")

        let progressTimer = ProgressTimer(from: 0.0, to: 0.95, duration: 60, callback: progress)
        progressTimer.start()

        whisperKit = try await WhisperKit(
            modelFolder: modelFolder.path,
            verbose: false,
            prewarm: true,
            load: true,
            download: false
        )

        progressTimer.stop()
        progress(1.0)
        owLog("[Whisper] CoreML model compiled and loaded")

        // Delete other models to save disk space — only keep the active one
        removeOtherModels(keeping: name, in: modelBase)
    }

    struct TranscribeResult {
        let text: String
        let detectedLanguage: String
    }

    /// Transcribe audio
    func transcribe(audioData: [Float], language: String, translateToEnglish: Bool = false) async throws -> TranscribeResult {
        guard let whisperKit else {
            throw TranscriberError.modelNotLoaded
        }

        let task: DecodingTask = translateToEnglish ? .translate : .transcribe
        owLog("[Whisper] Transcribing with language='\(language)' task=\(task) samples=\(audioData.count)")

        let options = DecodingOptions(
            task: task,
            language: language.isEmpty ? nil : language,
            temperature: 0.0,
            temperatureFallbackCount: 3,
            sampleLength: 224,
            suppressBlank: true,
            supressTokens: nil,
            compressionRatioThreshold: 2.4,
            logProbThreshold: -1.0,
            noSpeechThreshold: 0.8
        )

        let results = try await whisperKit.transcribe(
            audioArray: audioData,
            decodeOptions: options
        )

        let detectedLang = results.first?.language ?? ""
        for (i, result) in results.enumerated() {
            owLog("[Whisper] Result[\(i)] language=\(result.language) text=\(result.text)")
        }

        let text = results
            .compactMap { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Filter hallucinations
        let hallucinations: Set<String> = [
            "Thank you.", "Thanks for watching.", "Subscribe.",
            "you", "You", ".", "", "...", "Thank you for watching.",
            "Bye.", "Bye bye.", "Bye-bye.", "The end.",
            "Thanks.", "Thank you so much.", "See you next time.",
            "Please subscribe.", "Like and subscribe.",
            "Thank you for listening.", "Thanks for listening.",
            "Don't forget to subscribe.", "Hit the like button.",
            "See you in the next video.", "See you in the next one.",
            "Please like and subscribe.", "Goodbye.", "Good bye.",
            "谢谢大家", "谢谢观看", "谢谢收看", "谢谢",
            "一键三连", "点赞", "订阅", "转发",
            "感谢观看", "感谢收听", "感谢大家",
            "请订阅", "请点赞", "别忘了点赞",
            "下次再见", "我们下期再见", "再见",
            "字幕by", "字幕", "潜水艇字幕",
        ]
        let empty = TranscribeResult(text: "", detectedLanguage: detectedLang)
        if hallucinations.contains(text) { return empty }
        if text.hasPrefix("[") || text.hasPrefix("(") { return empty }

        // Amara.org subtitles hallucination (often appended to real text)
        let amaraPatterns = ["amara.org", "subtitles by", "字幕由"]
        let lowerForAmara = text.lowercased()
        for p in amaraPatterns {
            if lowerForAmara.contains(p) {
                let cleaned = text.replacingOccurrences(
                    of: "\\s*Subtitles by the Amara\\.org[e]? community\\.?",
                    with: "", options: .regularExpression
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.isEmpty { return empty }
                return TranscribeResult(text: cleaned, detectedLanguage: detectedLang)
            }
        }
        // Min length: CJK characters carry more meaning per char than Latin
        let hasCJK = text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
        let minLen = hasCJK ? 1 : 3
        if text.count < minLen { return empty }

        let hallucinationPatterns = [
            "请不吝", "点赞订阅", "打赏支持", "明镜", "点点栏目",
            "字幕组", "字幕制作", "字幕製作", "翻译校对", "翻譯校對",
            "贝尔", "貝爾", "索尼", "华纳",
            "欢迎订阅", "关注我们", "点击订阅",
            "支持明镜", "请订阅转发",
            "subscribe", "like button", "next video",
            "don't forget to", "hit the bell",
            "leave a comment", "share this video",
        ]
        let lowerText = text.lowercased()
        for pattern in hallucinationPatterns {
            if lowerText.contains(pattern.lowercased()) { return empty }
        }

        let words = text.components(separatedBy: " ").filter { !$0.isEmpty }
        if words.count >= 4 {
            let unique = Set(words)
            if unique.count <= 2 { return empty }
        }

        // Strip trailing hallucination phrases that Whisper appends to real content
        var cleaned = text
        let trailingHallucinations = [
            "谢谢大家", "谢谢观看", "谢谢收看", "谢谢收听", "谢谢",
            "感谢观看", "感谢收听", "感谢大家",
            "请订阅", "请点赞", "一键三连",
            "下次再见", "我们下期再见", "再见",
            "Thank you.", "Thanks for watching.",
            "See you next time.", "Goodbye.",
        ]
        for suffix in trailingHallucinations {
            if cleaned.hasSuffix(suffix) && cleaned.count > suffix.count {
                cleaned = String(cleaned.dropLast(suffix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "，。、,. "))
                break
            }
        }
        if cleaned.isEmpty { return empty }

        return TranscribeResult(text: cleaned, detectedLanguage: detectedLang)
    }

    /// Keep only the 2 most recent models on disk
    private func removeOtherModels(keeping activeName: String, in modelBase: URL) {
        let fm = FileManager.default
        let activeModel = "openai_whisper-\(activeName)"
        guard let repos = try? fm.contentsOfDirectory(at: modelBase, includingPropertiesForKeys: nil) else { return }
        for repo in repos where repo.hasDirectoryPath {
            guard let variants = try? fm.contentsOfDirectory(
                at: repo, includingPropertiesForKeys: [.contentModificationDateKey]
            ) else { continue }

            let models = variants
                .filter { $0.hasDirectoryPath && !$0.lastPathComponent.hasPrefix(".") }
                .sorted {
                    let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                    let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                    return d1 > d2
                }

            var kept = Set<String>()
            kept.insert(activeModel)
            for model in models where kept.count < 2 {
                kept.insert(model.lastPathComponent)
            }

            for model in models where !kept.contains(model.lastPathComponent) {
                try? fm.removeItem(at: model)
                owLog("[Whisper] Removed old model: \(model.lastPathComponent)")
            }
        }
    }
}

enum TranscriberError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: "Whisper model is not loaded."
        }
    }
}

// MARK: - Progress Timer

/// Animates progress from `from` to `to` over `duration` seconds, giving the user visual feedback
/// during long operations (like CoreML compilation) that don't report their own progress.
final class ProgressTimer: @unchecked Sendable {
    private let from: Double
    private let to: Double
    private let duration: TimeInterval
    private let callback: @Sendable (Double) -> Void
    private var timer: Timer?
    private let startTime = Date()

    init(from: Double, to: Double, duration: TimeInterval, callback: @escaping @Sendable (Double) -> Void) {
        self.from = from
        self.to = to
        self.duration = duration
        self.callback = callback
    }

    func start() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                guard let self else { return }
                let elapsed = Date().timeIntervalSince(self.startTime)
                let t = min(elapsed / self.duration, 1.0)
                let eased = 1.0 - pow(1.0 - t, 3)
                let value = self.from + (self.to - self.from) * eased
                self.callback(value)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
