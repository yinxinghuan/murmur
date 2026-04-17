import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState

    private var zh: Bool { appState.uiLanguage == "zh" }
    private let R: CGFloat = 200
    @State private var showAdvanced = false

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 12) {

            // ── Header ──
            HStack(spacing: 10) {
                MurmurLogo(color: Color.primary).frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Murmur").font(.system(size: 18, weight: .semibold))
                    Text(zh ? "本地语音转文字" : "Local voice to text")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $appState.uiLanguage) {
                    Text("中").tag("zh")
                    Text("EN").tag("en")
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 72)
            }

            // ── Onboarding ──
            if appState.isFirstLaunch { onboardingCard }

            // ── Permission warnings ──
            if !appState.isFirstLaunch && (!appState.microphoneGranted || !appState.accessibilityGranted) {
                permissionWarnings
            }

            Divider()

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // BASIC — always visible
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━

            // Model
            row(zh ? "语音模型" : "Model", icon: "waveform") {
                Picker("", selection: $appState.whisperModel) {
                    ForEach(whisperModels, id: \.name) { m in
                        Text(m.displayLabel(
                            downloaded: appState.downloadedWhisperModels.contains(m.name),
                            recommended: m.name == recommendedModel, zh: zh
                        )).tag(m.name)
                    }
                }
                .labelsHidden().frame(width: R, alignment: .trailing)
                .id(appState.downloadedWhisperModels)
                .onChange(of: appState.whisperModel) { Task { await appState.loadModel() } }
            }
            modelStatus

            // Language
            row(zh ? "输入语言" : "Language", icon: "globe") {
                Picker("", selection: $appState.language) {
                    Text(zh ? "自动检测" : "Auto").tag("")
                    Text("中文").tag("zh")
                    Text("English").tag("en")
                    Text("日本語").tag("ja")
                    Text("한국어").tag("ko")
                    Text("Español").tag("es")
                    Text("Français").tag("fr")
                    Text("Deutsch").tag("de")
                }
                .labelsHidden().frame(width: R, alignment: .trailing)
            }

            // Hotkey
            row(zh ? "快捷键" : "Hotkey", icon: "command") {
                Text("Right ⌥")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor))
                    .frame(width: R, alignment: .trailing)
            }

            // Mode
            row(zh ? "录音方式" : "Mode", icon: "hand.tap") {
                Picker("", selection: $appState.dictationMode) {
                    Text(zh ? "按住" : "Hold").tag("hold")
                    Text(zh ? "切换" : "Toggle").tag("toggle")
                }
                .labelsHidden().pickerStyle(.segmented)
                .frame(width: R, alignment: .trailing)
            }

            Divider()

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // BASIC SETTINGS — everyday use
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━

            // Text polish
            row(zh ? "文本润色" : "Text polish", icon: "sparkle") {
                HStack(spacing: 6) {
                    if appState.llmCleanupEnabled {
                        Text(appState.ollamaAvailable ? (zh ? "已连接" : "OK") : (zh ? "未连接" : "Off"))
                            .font(.caption2)
                            .foregroundStyle(appState.ollamaAvailable ? Color.secondary : Color.orange)
                    }
                    Toggle("", isOn: $appState.llmCleanupEnabled)
                        .toggleStyle(.switch).labelsHidden().controlSize(.mini)
                }.frame(width: R, alignment: .trailing)
            }
            if appState.llmCleanupEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    if !appState.ollamaAvailable {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange).font(.system(size: 11))
                            Text(zh ? "请先启动 Ollama" : "Start Ollama first")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button("ollama.com") {
                                NSWorkspace.shared.open(URL(string: "https://ollama.com")!)
                            }.buttonStyle(.plain).font(.caption).foregroundStyle(.blue)
                        }
                    }
                    row(zh ? "润色模型" : "LLM", icon: "cpu") {
                        Picker("", selection: $appState.llmModel) {
                            llmModelLabel("qwen2.5:1.5b (986 MB)", name: "qwen2.5:1.5b")
                            llmModelLabel("qwen2.5:3b (1.9 GB)", name: "qwen2.5:3b")
                            llmModelLabel("qwen2.5:7b (4.7 GB)", name: "qwen2.5:7b")
                        }
                        .labelsHidden().frame(width: R, alignment: .trailing)
                    }
                }
                .padding(.leading, 12)
            }

            // Auto-paste
            row(zh ? "自动粘贴" : "Auto-paste", icon: "doc.on.clipboard") {
                Toggle("", isOn: $appState.autoPasteEnabled)
                    .toggleStyle(.switch).labelsHidden().controlSize(.mini)
                    .frame(width: R, alignment: .trailing)
            }

            // Flow bar theme (always on, just pick style)
            row(zh ? "悬浮条" : "Flow Bar", icon: "capsule") {
                Picker("", selection: $appState.flowBarTheme) {
                    Text(zh ? "黑底" : "Dark").tag("voiceFirst")
                    Text(zh ? "白底" : "Light").tag("invert")
                }.labelsHidden().pickerStyle(.segmented)
                .frame(width: R, alignment: .trailing)
            }

            // Launch at login
            row(zh ? "开机启动" : "Auto-start", icon: "power") {
                Toggle("", isOn: $appState.launchAtLogin)
                    .toggleStyle(.switch).labelsHidden().controlSize(.mini)
                    .frame(width: R, alignment: .trailing)
            }

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // ADVANCED — specialized features
            // Each toggle-to-expand, invisible when off
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━

            Divider()

            // Chinese format (conditional)
            if (appState.language == "zh" || appState.language == "") && !appState.translateToEnglish {
                row(zh ? "中文格式" : "Chinese", icon: "character") {
                    Picker("", selection: $appState.chineseVariant) {
                        Text(zh ? "简体" : "简").tag("simplified")
                        Text(zh ? "繁體" : "繁").tag("traditional")
                        Text(zh ? "不转换" : "Auto").tag("auto")
                    }
                    .labelsHidden().pickerStyle(.segmented)
                    .frame(width: R, alignment: .trailing)
                }
            }

            // Translation (conditional)
            if appState.language != "en" && appState.whisperModel != "small.en" {
                row(zh ? "翻译输出" : "Translate", icon: "character.bubble") {
                    Picker("", selection: $appState.translateToEnglish) {
                        Text(zh ? "原文" : "Off").tag(false)
                        Text(zh ? "译为英文" : "→ EN").tag(true)
                    }
                    .labelsHidden().pickerStyle(.segmented)
                    .frame(width: R, alignment: .trailing)
                }
            }

            // Advanced — collapsed by default
            HStack {
                Text(zh ? "高级功能" : "Advanced")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { showAdvanced.toggle() }
            }

            if showAdvanced {
                // Voice commands
                row(zh ? "语音指令" : "Voice Cmd", icon: "mic.badge.plus") {
                    Toggle("", isOn: $appState.voiceCommandsEnabled)
                        .toggleStyle(.switch).labelsHidden().controlSize(.mini)
                        .frame(width: R, alignment: .trailing)
                }
                if appState.voiceCommandsEnabled {
                    Text(zh ? "在语音末尾说指令来控制键盘操作" : "Say a command at end of speech")
                        .font(.caption).foregroundStyle(.tertiary)
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(zh ? "\"换行\" → ↵" : "\"new line\" → ↵").font(.caption2)
                            Text(zh ? "\"发送\" → ↵" : "\"send\" → ↵").font(.caption2)
                            Text(zh ? "\"删除\" → ⌫" : "\"delete\" → ⌫").font(.caption2)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(zh ? "\"撤销\" → ⌘Z" : "\"undo\" → ⌘Z").font(.caption2)
                            Text(zh ? "\"全选\" → ⌘A" : "\"select all\" → ⌘A").font(.caption2)
                        }
                    }
                    .foregroundStyle(.tertiary).padding(.leading, 12)
                }

                // Protected terms (only when LLM is on)
                if appState.llmCleanupEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(zh ? "保护术语（逗号分隔）" : "Protected terms (comma separated)")
                            .font(.caption).foregroundStyle(.secondary)
                        TextField(zh ? "如: useState, API" : "e.g. useState, API", text: $appState.customTerms)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                        Text(zh ? "文本润色时保持这些术语不被修改" : "Keep these terms unchanged during text polish")
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                }
            }

            Divider()

            // ── Quit ──
            HStack {
                Label(zh ? "退出 Murmur" : "Quit Murmur", systemImage: "xmark.circle")
                Spacer()
                Text("v1.2.0").font(.caption).foregroundStyle(.tertiary)
            }
            .onTapGesture { NSApplication.shared.terminate(nil) }
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

    // MARK: - Row Builder

    private func row<Content: View>(_ label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            content()
        }
    }

    // MARK: - Model Status

    @ViewBuilder
    private var modelStatus: some View {
        if appState.modelLoading {
            HStack(spacing: 6) {
                ProgressView(value: appState.modelLoadProgress).frame(maxWidth: .infinity)
                Text("\(Int(appState.modelLoadProgress * 100))%")
                    .font(.caption).foregroundStyle(.secondary).frame(width: 32, alignment: .trailing)
            }
        } else if let failed = appState.failedModelName {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange).font(.system(size: 11))
                    Text(zh ? "\(failed) 下载不完整" : "\(failed) incomplete")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Button(zh ? "重新下载" : "Re-download") { appState.retryModelDownload() }
                        .buttonStyle(.borderedProminent).controlSize(.small)
                    if appState.findFallbackModel() != nil {
                        Button(zh ? "使用其他模型" : "Use another") {
                            if let fb = appState.findFallbackModel() {
                                appState.failedModelName = nil
                                appState.whisperModel = fb
                                Task { await appState.loadModel() }
                            }
                        }.buttonStyle(.bordered).controlSize(.small)
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08)))
        } else if !appState.modelLoaded {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange).font(.system(size: 11))
                Text(zh ? "模型未加载" : "No model").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(zh ? "下载" : "Download") { Task { await appState.loadModel() } }
                    .buttonStyle(.bordered).controlSize(.mini)
            }
        }
    }

    // MARK: - Onboarding

    private var onboardingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(zh ? "快速开始" : "Quick Start").font(.system(size: 14, weight: .semibold))

            HStack(alignment: .top, spacing: 10) {
                stepCircle("1", done: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(zh ? "按住右 ⌥ 说话" : "Hold Right ⌥ to speak").font(.system(size: 13, weight: .medium))
                    Text(zh ? "松开后文字自动粘贴到光标处" : "Release to auto-paste at cursor")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                stepCircle("2", done: appState.microphoneGranted && appState.accessibilityGranted)
                VStack(alignment: .leading, spacing: 4) {
                    if appState.microphoneGranted && appState.accessibilityGranted {
                        Text(zh ? "权限已就绪" : "Permissions ready")
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                    } else {
                        Text(zh ? "授予权限" : "Grant permissions").font(.system(size: 13, weight: .medium))
                        if !appState.microphoneGranted {
                            Button(zh ? "→ 麦克风权限" : "→ Microphone") {
                                openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
                            }.buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(Color.accentColor)
                        }
                        if !appState.accessibilityGranted {
                            Button(zh ? "→ 辅助功能权限" : "→ Accessibility") {
                                openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                            }.buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }

            HStack(alignment: .top, spacing: 10) {
                stepCircle("3", done: appState.modelLoaded)
                if appState.modelLoaded {
                    Text(zh ? "模型已就绪" : "Model ready")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                } else if appState.modelLoading {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zh ? "模型下载中 \(Int(appState.modelLoadProgress * 100))%" : "Downloading \(Int(appState.modelLoadProgress * 100))%")
                            .font(.system(size: 13, weight: .medium))
                        ProgressView(value: appState.modelLoadProgress).frame(maxWidth: .infinity)
                    }
                } else {
                    Text(zh ? "请在下方选择模型" : "Select a model below")
                        .font(.system(size: 13, weight: .medium))
                }
            }

            if appState.modelLoaded && appState.microphoneGranted && appState.accessibilityGranted {
                Button(zh ? "开始使用" : "Get Started") { appState.dismissOnboarding() }
                    .buttonStyle(.borderedProminent).controlSize(.regular)
                    .frame(maxWidth: .infinity).padding(.top, 4)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(0.06)))
    }

    // MARK: - Permission Warnings

    private var permissionWarnings: some View {
        VStack(spacing: 6) {
            if !appState.microphoneGranted {
                permissionWarning(zh ? "需要麦克风权限" : "Microphone access needed",
                    action: { openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") })
            }
            if !appState.accessibilityGranted {
                permissionWarning(zh ? "需要辅助功能权限" : "Accessibility access needed",
                    action: { openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") })
            }
        }
    }

    // MARK: - Helpers

    private func stepCircle(_ num: String, done: Bool) -> some View {
        Group {
            if done {
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white).frame(width: 22, height: 22)
                    .background(Circle().fill(Color.primary))
            } else {
                Text(num).font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white).frame(width: 22, height: 22)
                    .background(Circle().fill(Color.accentColor))
            }
        }
    }

    private func permissionWarning(_ text: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.system(size: 12))
            Text(text).font(.callout)
            Spacer()
            Button(zh ? "授权" : "Grant") { action() }.buttonStyle(.bordered).controlSize(.small)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(.orange.opacity(0.1)))
    }

    // MARK: - Model Data

    private struct WhisperModel {
        let name, label, size: String
        let minRAM: Int
        func displayLabel(downloaded: Bool, recommended: Bool, zh: Bool) -> String {
            var s = "\(label) (\(size))"
            if recommended { s += zh ? " ★推荐" : " ★" }
            if !downloaded { s += " ⤓" }
            return s
        }
    }

    private var whisperModels: [WhisperModel] {[
        .init(name: "tiny", label: "Tiny", size: "39 MB", minRAM: 4),
        .init(name: "base", label: "Base", size: "140 MB", minRAM: 4),
        .init(name: "small", label: "Small", size: "460 MB", minRAM: 8),
        .init(name: "small.en", label: "Small EN", size: "460 MB", minRAM: 8),
        .init(name: "large-v3_turbo", label: "Large v3 Turbo", size: "1.6 GB", minRAM: 16),
        .init(name: "large-v3", label: "Large v3", size: "3 GB", minRAM: 24),
    ]}

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

// MARK: - Label Style

struct SettingsLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.font(.system(size: 15)).foregroundStyle(.primary)
                .frame(width: 22, alignment: .center)
            configuration.title
        }
    }
}
