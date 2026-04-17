import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState

    private var zh: Bool { appState.uiLanguage == "zh" }

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                MurmurLogo(color: Color.primary)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Murmur")
                        .font(.system(size: 18, weight: .semibold))
                    Text(zh ? "本地语音转文字" : "Local voice to text")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // First-launch onboarding
            if appState.isFirstLaunch {
                VStack(alignment: .leading, spacing: 14) {
                    Text(zh ? "快速开始" : "Quick Start")
                        .font(.system(size: 14, weight: .semibold))

                    // Step 1: How to use
                    HStack(alignment: .top, spacing: 10) {
                        stepCircle("1", done: false)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(zh ? "按住右 ⌥ 说话" : "Hold Right ⌥ to speak")
                                .font(.system(size: 13, weight: .medium))
                            Text(zh ? "松开后文字自动粘贴到光标处" : "Release to auto-paste at cursor")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Step 2: Permissions
                    HStack(alignment: .top, spacing: 10) {
                        stepCircle("2", done: appState.microphoneGranted && appState.accessibilityGranted)
                        VStack(alignment: .leading, spacing: 4) {
                            if appState.microphoneGranted && appState.accessibilityGranted {
                                Text(zh ? "权限已就绪" : "Permissions ready")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(zh ? "授予权限" : "Grant permissions")
                                    .font(.system(size: 13, weight: .medium))
                                if !appState.microphoneGranted {
                                    Button(zh ? "→ 麦克风权限" : "→ Microphone") {
                                        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
                                    }
                                    .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(Color.accentColor)
                                }
                                if !appState.accessibilityGranted {
                                    Button(zh ? "→ 辅助功能权限" : "→ Accessibility") {
                                        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                                    }
                                    .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }

                    // Step 3: Model
                    HStack(alignment: .top, spacing: 10) {
                        stepCircle("3", done: appState.modelLoaded)
                        VStack(alignment: .leading, spacing: 2) {
                            if appState.modelLoaded {
                                Text(zh ? "模型已就绪" : "Model ready")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                            } else if appState.modelLoading {
                                Text(zh ? "模型下载中 \(Int(appState.modelLoadProgress * 100))%" : "Downloading \(Int(appState.modelLoadProgress * 100))%")
                                    .font(.system(size: 13, weight: .medium))
                                ProgressView(value: appState.modelLoadProgress)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text(zh ? "请在下方选择模型" : "Select a model below")
                                    .font(.system(size: 13, weight: .medium))
                            }
                        }
                    }

                    // Dismiss
                    if appState.modelLoaded && appState.microphoneGranted && appState.accessibilityGranted {
                        Button(zh ? "开始使用" : "Get Started") {
                            appState.dismissOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(0.06)))
            }

            // Permission warnings (only show after onboarding dismissed)
            if !appState.isFirstLaunch && (!appState.microphoneGranted || !appState.accessibilityGranted) {
                VStack(spacing: 6) {
                    if !appState.microphoneGranted {
                        permissionWarning(
                            zh ? "需要麦克风权限" : "Microphone access needed",
                            action: { openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") }
                        )
                    }
                    if !appState.accessibilityGranted {
                        permissionWarning(
                            zh ? "需要辅助功能权限" : "Accessibility access needed",
                            action: { openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") }
                        )
                    }
                }
            }

            Divider()

            // Model selector
            HStack {
                Label(zh ? "语音模型" : "Model", systemImage: "waveform")
                Spacer()
                Picker("", selection: $appState.whisperModel) {
                    ForEach(whisperModels, id: \.name) { m in
                        Text(m.displayLabel(
                            downloaded: appState.downloadedWhisperModels.contains(m.name),
                            recommended: m.name == recommendedModel,
                            zh: zh
                        )).tag(m.name)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .id(appState.downloadedWhisperModels)  // Force Picker refresh when download state changes
                .onChange(of: appState.whisperModel) {
                    Task { await appState.loadModel() }
                }
                // Open model folder button
                Button(action: { appState.openModelDirectory() }) {
                    Image(systemName: "folder")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(zh ? "打开模型目录" : "Open model folder")
            }

            // Model status
            if appState.modelLoading {
                HStack(spacing: 6) {
                    ProgressView(value: appState.modelLoadProgress)
                        .frame(maxWidth: .infinity)
                    Text("\(Int(appState.modelLoadProgress * 100))%")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .trailing)
                }
            } else if let failed = appState.failedModelName {
                // Model failed — let user choose
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.system(size: 11))
                        Text(zh ? "\(failed) 下载不完整" : "\(failed) incomplete")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        Button(zh ? "重新下载" : "Re-download") {
                            appState.retryModelDownload()
                        }
                        .buttonStyle(.borderedProminent).controlSize(.small)

                        if appState.findFallbackModel() != nil {
                            Button(zh ? "使用其他模型" : "Use another") {
                                if let fb = appState.findFallbackModel() {
                                    appState.failedModelName = nil
                                    appState.whisperModel = fb
                                    Task { await appState.loadModel() }
                                }
                            }
                            .buttonStyle(.bordered).controlSize(.small)
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08)))
            } else if !appState.modelLoaded {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.system(size: 11))
                    Text(zh ? "模型未加载" : "No model loaded")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button(zh ? "下载" : "Download") {
                        Task { await appState.loadModel() }
                    }
                    .buttonStyle(.bordered).controlSize(.mini)
                }
            }

            HStack {
                Label(zh ? "输入语言" : "Language", systemImage: "globe")
                Spacer()
                Picker("", selection: $appState.language) {
                    Text(zh ? "自动检测" : "Auto").tag("")
                    Text("中文").tag("zh")
                    Text("English").tag("en")
                    Text("日本語").tag("ja")
                    Text("한국어").tag("ko")
                    Text("Español").tag("es")
                    Text("Français").tag("fr")
                    Text("Deutsch").tag("de")
                    Text("Русский").tag("ru")
                    Text("Português").tag("pt")
                    Text("العربية").tag("ar")
                    Text("Italiano").tag("it")
                    Text("Tiếng Việt").tag("vi")
                    Text("ไทย").tag("th")
                    Text("हिन्दी").tag("hi")
                    Text("Bahasa").tag("id")
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Only show translation option when input language is not English
            if appState.language != "en" && appState.whisperModel != "small.en" {
                HStack {
                    Label(zh ? "输出" : "Output", systemImage: "character.bubble")
                    Spacer()
                    Picker("", selection: $appState.translateToEnglish) {
                        Text(zh ? "原文" : "Original").tag(false)
                        Text(zh ? "译为英文" : "→ English").tag(true)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            // Chinese variant (only show when language is Chinese)
            if appState.language == "zh" || appState.language == "" {
                HStack {
                    Label(zh ? "中文字体" : "Chinese", systemImage: "character")
                    Spacer()
                    Picker("", selection: $appState.chineseVariant) {
                        Text(zh ? "简体" : "简").tag("simplified")
                        Text(zh ? "繁體" : "繁").tag("traditional")
                        Text(zh ? "不转换" : "Auto").tag("auto")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }

            Divider()

            // LLM Cleanup
            HStack {
                Label(zh ? "文本润色" : "Text polish", systemImage: "sparkle")
                Spacer()
                if appState.llmCleanupEnabled {
                    Text(appState.ollamaAvailable
                         ? (zh ? "已连接" : "Connected")
                         : (zh ? "未连接" : "Offline"))
                        .font(.caption2)
                        .foregroundStyle(appState.ollamaAvailable ? Color.secondary : Color.orange)
                }
                Toggle("", isOn: $appState.llmCleanupEnabled)
                    .toggleStyle(.switch).labelsHidden().controlSize(.mini)
            }

            if appState.llmCleanupEnabled {
                if !appState.ollamaAvailable {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange).font(.system(size: 11))
                        Text(zh ? "请先启动 Ollama" : "Please start Ollama first")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button("ollama.com") {
                            NSWorkspace.shared.open(URL(string: "https://ollama.com")!)
                        }
                        .buttonStyle(.plain).font(.caption).foregroundStyle(.blue)
                    }
                }
                HStack {
                    Label(zh ? "润色模型" : "LLM Model", systemImage: "cpu")
                    Spacer()
                    Picker("", selection: $appState.llmModel) {
                        llmModelLabel("qwen2.5:1.5b (986 MB)", name: "qwen2.5:1.5b")
                        llmModelLabel("qwen2.5:3b (1.9 GB)", name: "qwen2.5:3b")
                        llmModelLabel("qwen2.5:7b (4.7 GB)", name: "qwen2.5:7b")
                        llmModelLabel("gemma4:e4b (9.6 GB)", name: "gemma4:e4b")
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Protected terms
                VStack(alignment: .leading, spacing: 4) {
                    Text(zh ? "保护术语（逗号分隔）" : "Protected terms (comma separated)")
                        .font(.caption).foregroundStyle(.secondary)
                    TextField(
                        zh ? "如: useState, API, onClick" : "e.g. useState, API, onClick",
                        text: $appState.customTerms
                    )
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                }
            }

            Divider()

            HStack {
                Label(zh ? "自动粘贴" : "Auto-paste", systemImage: "doc.on.clipboard")
                Spacer()
                Toggle("", isOn: $appState.autoPasteEnabled)
                    .toggleStyle(.switch).labelsHidden().controlSize(.mini)
            }

            HStack {
                Label(zh ? "悬浮条" : "Flow Bar", systemImage: "capsule")
                Spacer()
                if appState.flowBarEnabled {
                    Picker("", selection: $appState.flowBarTheme) {
                        Text(zh ? "黑底" : "Dark").tag("voiceFirst")
                        Text(zh ? "白底" : "Light").tag("invert")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }
                Toggle("", isOn: $appState.flowBarEnabled)
                    .toggleStyle(.switch).labelsHidden().controlSize(.mini)
            }

            HStack {
                Label(zh ? "开机启动" : "Launch at Login", systemImage: "power")
                Spacer()
                Toggle("", isOn: $appState.launchAtLogin)
                    .toggleStyle(.switch).labelsHidden().controlSize(.mini)
            }

            HStack {
                Label(zh ? "界面语言" : "UI Language", systemImage: "translate")
                Spacer()
                Picker("", selection: $appState.uiLanguage) {
                    Text("中文").tag("zh")
                    Text("EN").tag("en")
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

            HStack {
                Label(zh ? "快捷键" : "Hotkey", systemImage: "command")
                Spacer()
                Text(zh ? "按住右 ⌥" : "Hold Right ⌥")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor))
            }

            Divider()

            // Quit — same style as other rows
            HStack {
                Label(zh ? "退出 Murmur" : "Quit Murmur", systemImage: "xmark.circle")
                Spacer()
                Text("v1.0.0").font(.caption).foregroundStyle(.tertiary)
            }
            .onTapGesture {
                NSApplication.shared.terminate(nil)
            }
        }
        .labelStyle(SettingsLabelStyle())
        .tint(.accentColor)
        .padding(16)
        .frame(width: 340)
        .onAppear {
            appState.refreshPermissions()
            appState.refreshDownloadedModels()
            Task {
                await appState.refreshOllamaStatus()
                await appState.refreshInstalledLLMModels()
            }
        }
    }

    // MARK: - Helpers

    private func stepCircle(_ num: String, done: Bool) -> some View {
        Group {
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.primary))
            } else {
                Text(num)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.accentColor))
            }
        }
    }

    private func permissionWarning(_ text: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 12))
            Text(text)
                .font(.callout)
            Spacer()
            Button(zh ? "授权" : "Grant") { action() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(.orange.opacity(0.1)))
    }

    // MARK: - Whisper Model Data

    private struct WhisperModel {
        let name: String
        let label: String
        let size: String
        let minRAM: Int  // GB

        func displayLabel(downloaded: Bool, recommended: Bool, zh: Bool) -> String {
            var s = "\(label) (\(size))"
            if recommended { s += zh ? " ★推荐" : " ★" }
            if !downloaded { s += " ⤓" }
            return s
        }
    }

    private var whisperModels: [WhisperModel] {
        [
            WhisperModel(name: "tiny", label: "Tiny", size: "39 MB", minRAM: 4),
            WhisperModel(name: "base", label: "Base", size: "140 MB", minRAM: 4),
            WhisperModel(name: "small", label: "Small", size: "460 MB", minRAM: 8),
            WhisperModel(name: "small.en", label: "Small EN", size: "460 MB", minRAM: 8),
            WhisperModel(name: "large-v3_turbo", label: "Large v3 Turbo", size: "1.6 GB", minRAM: 16),
            WhisperModel(name: "large-v3", label: "Large v3", size: "3 GB", minRAM: 24),
        ]
    }

    private var recommendedModel: String {
        let ram = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024))
        if ram >= 24 { return "large-v3" }
        if ram >= 16 { return "large-v3_turbo" }
        if ram >= 8 { return "small" }
        return "base"
    }

    private func llmModelLabel(_ label: String, name: String) -> some View {
        let installed = appState.installedLLMModels.contains(name)
        return Text("\(label)\(installed ? "" : " ⤓")").tag(name)
    }

    private func openSystemSettings(_ url: String) {
        if let url = URL(string: url) { NSWorkspace.shared.open(url) }
    }
}

// MARK: - Unified Label Style (fixed icon width for alignment)

struct SettingsLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .frame(width: 22, alignment: .center)
            configuration.title
        }
    }
}

// StatusBadge removed — state is shown via menu bar icon
