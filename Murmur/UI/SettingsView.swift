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

            // Permission warnings (only show if not granted)
            if !appState.microphoneGranted || !appState.accessibilityGranted {
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

            // Model
            HStack {
                Label(zh ? "语音模型" : "Model", systemImage: "waveform")
                Spacer()
                Picker("", selection: $appState.whisperModel) {
                    whisperModelLabel("Tiny (39 MB)", name: "tiny")
                    whisperModelLabel("Base (140 MB)", name: "base")
                    whisperModelLabel("Small (460 MB)", name: "small")
                    whisperModelLabel("Small EN", name: "small.en")
                    whisperModelLabel("Large v3 (3 GB)", name: "large-v3")
                    whisperModelLabel("Large v3 Turbo (1.6 GB)", name: "large-v3_turbo")
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .onChange(of: appState.whisperModel) {
                    Task { await appState.loadModel() }
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

            HStack {
                Label(zh ? "输出" : "Output", systemImage: "character.bubble")
                Spacer()
                Picker("", selection: $appState.translateToEnglish) {
                    Text(zh ? "原文" : "Original").tag(false)
                    Text(zh ? "译为英文" : "English").tag(true)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Divider()

            // LLM Cleanup
            HStack {
                Label(zh ? "文本润色" : "Text polish", systemImage: "sparkle")
                Spacer()
                if appState.llmCleanupEnabled {
                    Circle()
                        .fill(appState.ollamaAvailable ? Color.primary : Color.red)
                        .frame(width: 5, height: 5)
                }
                Toggle("", isOn: $appState.llmCleanupEnabled)
                    .toggleStyle(.switch).labelsHidden().controlSize(.mini)
            }

            if appState.llmCleanupEnabled {
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
                    .background(RoundedRectangle(cornerRadius: 6).fill(.black))
            }

            // Status
            if appState.modelLoading {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(appState.modelLoadProgress > 0
                         ? (appState.modelIsDownloading
                            ? "\(zh ? "下载中" : "Downloading") \(Int(appState.modelLoadProgress * 100))%"
                            : "\(zh ? "切换中" : "Switching")...")
                         : "\(zh ? "加载中" : "Loading")...")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else if !appState.modelLoaded {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle").foregroundStyle(.orange)
                    Text(zh ? "模型未加载" : "Model not loaded")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            if let error = appState.lastError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                    Text(error).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
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
        .tint(.black)
        .padding(16)
        .frame(width: 340)
        .onAppear {
            appState.refreshPermissions()
            appState.refreshDownloadedModels()
            Task { await appState.refreshInstalledLLMModels() }
        }
    }

    // MARK: - Helpers

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

    private func whisperModelLabel(_ label: String, name: String) -> some View {
        let downloaded = appState.downloadedWhisperModels.contains(name)
        return Text("\(label)\(downloaded ? "" : " ·")").tag(name)
    }

    private func llmModelLabel(_ label: String, name: String) -> some View {
        let installed = appState.installedLLMModels.contains(name)
        return Text("\(label)\(installed ? "" : " ·")").tag(name)
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
