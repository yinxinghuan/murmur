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

            // ── Permission warnings ──
            if !appState.microphoneGranted || !appState.accessibilityGranted {
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
                .labelsHidden().frame(width: R - 24, alignment: .trailing)
                .id(appState.downloadedWhisperModels)
                .onChange(of: appState.whisperModel) { Task { await appState.loadModel() } }
                Button(action: {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: WhisperTranscriber.modelBaseURL.path)
                }) {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help(zh ? "打开模型目录" : "Open model folder")
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

            // Translation (before LLM — overrides polish)
            if appState.language != "en" && appState.whisperModel != "small.en" {
                row(zh ? "翻译输出" : "Translate", icon: "character.bubble") {
                    Picker("", selection: $appState.translateToEnglish) {
                        Text(zh ? "原文" : "Off").tag(false)
                        Text(zh ? "译为英文" : "→ EN").tag(true)
                    }
                    .labelsHidden().pickerStyle(.segmented)
                    .frame(width: R, alignment: .trailing)
                }
                if appState.translateToEnglish {
                    HStack {
                        Spacer()
                        Text(zh ? "翻译模式下不进行文本润色" : "Text polish is skipped in translation mode")
                            .font(.system(size: 12)).foregroundStyle(.tertiary)
                    }
                }
            }

            Divider()

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // BASIC SETTINGS — everyday use
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━

            // Text polish
            row(zh ? "文本润色" : "Text polish", icon: "sparkle") {
                HStack(spacing: 6) {
                    if appState.llmCleanupEnabled && !appState.translateToEnglish {
                        Text(appState.ollamaAvailable ? (zh ? "已连接" : "OK") : (zh ? "未连接" : "Off"))
                            .font(.caption2)
                            .foregroundStyle(appState.ollamaAvailable ? Color.secondary : Color.orange)
                    }
                    Toggle("", isOn: $appState.llmCleanupEnabled)
                        .toggleStyle(.switch).labelsHidden().controlSize(.mini)
                        .disabled(appState.translateToEnglish)
                }.frame(width: R, alignment: .trailing)
            }
            .opacity(appState.translateToEnglish ? 0.4 : 1.0)
            if appState.llmCleanupEnabled && !appState.translateToEnglish {
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
                            llmModelLabel("qwen2.5:1.5b (986 MB)", name: "qwen2.5:1.5b", recommended: false)
                            llmModelLabel("qwen2.5:3b (1.9 GB)", name: "qwen2.5:3b", recommended: true)
                            llmModelLabel("qwen2.5:7b (4.7 GB)", name: "qwen2.5:7b", recommended: false)
                        }
                        .labelsHidden().frame(width: R - 24, alignment: .trailing)
                        .disabled(!appState.ollamaAvailable)
                        Button(action: {
                            let ollamaDir = FileManager.default.homeDirectoryForCurrentUser
                                .appendingPathComponent(".ollama/models")
                            if FileManager.default.fileExists(atPath: ollamaDir.path) {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: ollamaDir.path)
                            } else {
                                NSWorkspace.shared.open(URL(string: "https://ollama.com")!)
                            }
                        }) {
                            Image(systemName: "folder")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .help(zh ? "打开 Ollama 模型目录" : "Open Ollama model folder")
                        .onChange(of: appState.llmModel) {
                            if appState.llmModel == "qwen2.5:1.5b" {
                                appState.polishStyle = "spoken"
                            }
                            Task { await appState.pullLLMModelIfNeeded() }
                        }
                    }
                    if appState.llmPulling {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(appState.llmPullProgress)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.leading, 30)
                    }
                    row(zh ? "润色风格" : "Style", icon: "paintpalette") {
                        Picker("", selection: $appState.polishStyle) {
                            if appState.llmModel != "qwen2.5:1.5b" {
                                Text(zh ? "自动" : "Auto").tag("auto")
                            }
                            Text(zh ? "口语" : "Spoken").tag("spoken")
                            Text(zh ? "自然" : "Natural").tag("natural")
                            if appState.llmModel != "qwen2.5:1.5b" {
                                Text(zh ? "精简" : "Concise").tag("concise")
                                Text(zh ? "结构化 β" : "Structured β").tag("structured")
                                Text(zh ? "自定义" : "Custom").tag("custom")
                            }
                        }
                        .labelsHidden().frame(width: R, alignment: .trailing)
                        .disabled(!appState.ollamaAvailable)
                    }
                    StyleDescription(style: appState.polishStyle, zh: zh, customPrompt: $appState.customPolishPrompt)
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

            // Chinese format
            if appState.language == "zh" || appState.language == "" {
                row(zh ? "中文格式" : "Chinese", icon: "character") {
                    Picker("", selection: $appState.chineseVariant) {
                        Text(zh ? "简体" : "简").tag("simplified")
                        Text(zh ? "繁體" : "繁").tag("traditional")
                        Text(zh ? "不转换" : "Auto").tag("auto")
                    }
                    .labelsHidden().pickerStyle(.segmented)
                    .frame(width: R, alignment: .trailing)
                    .disabled(appState.translateToEnglish)
                }
                .opacity(appState.translateToEnglish ? 0.4 : 1.0)
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
                // Protected terms (only when LLM is on)
                if appState.llmCleanupEnabled {
                    row(zh ? "术语保护" : "Term Guard", icon: "shield") {
                        Text(appState.protectedTerms.isEmpty
                             ? (zh ? "未设置" : "None")
                             : "\(appState.protectedTerms.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: R, alignment: .trailing)
                    }
                    ProtectedTermsView(
                        terms: $appState.protectedTerms,
                        zh: zh,
                        onAcceptSuggestion: { appState.acceptSuggestedTerm($0) },
                        onDismissSuggestion: { appState.dismissSuggestedTerm($0) },
                        smartSuggestions: appState.suggestedTerms
                    )
                        .padding(.leading, 12)
                }
            }

            Divider()

            // ── Quit ──
            HStack {
                Label(zh ? "退出 Murmur" : "Quit Murmur", systemImage: "xmark.circle")
                Spacer()
                if let latest = appState.latestVersion {
                    Button {
                        NSWorkspace.shared.open(URL(string: "https://github.com/yinxinghuan/murmur/releases/latest")!)
                    } label: {
                        Text(zh ? "v\(latest) 可更新" : "v\(latest) available")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor))
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("v\(AppState.currentVersion)").font(.caption).foregroundStyle(.tertiary)
                }
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
                await appState.checkForUpdate()
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

    private func llmModelLabel(_ label: String, name: String, recommended: Bool = false) -> some View {
        let installed = appState.installedLLMModels.contains(name)
        let zh = appState.uiLanguage == "zh"
        var s = label
        if recommended { s += zh ? " ★推荐" : " ★" }
        if !installed { s += " ⤓" }
        return Text(s).tag(name)
    }

    private func openSystemSettings(_ url: String) {
        if let url = URL(string: url) { NSWorkspace.shared.open(url) }
    }
}

// MARK: - Label Style

// MARK: - Style Description

struct StyleDescription: View {
    let style: String
    let zh: Bool
    @Binding var customPrompt: String
    @State private var showExample = false

    private var info: (desc: String, before: String, after: String)? {
        switch style {
        case "auto":
            return (
                zh ? "根据内容智能选择处理方式" : "Auto-selects the best style for your content",
                zh ? "改颜色加字段还有测试要写" : "Fix color, add field, also write tests",
                zh ? "1. 改颜色\n2. 加字段\n3. 写测试" : "1. Fix color\n2. Add field\n3. Write tests"
            )
        case "spoken":
            return (
                zh ? "最小干预，只加标点，保留所有原话" : "Minimal — only adds punctuation",
                zh ? "字体小了看着费劲" : "font is small hard to read",
                zh ? "字体小了，看着费劲。" : "Font is small, hard to read."
            )
        case "natural":
            return (
                zh ? "删除口语词，修正标点，保持原意" : "Remove filler words, fix punctuation",
                zh ? "嗯就是字体小了看着费劲" : "um like font is small hard to read",
                zh ? "字体小了，看着费劲。" : "Font is small, hard to read."
            )
        case "concise":
            return (
                zh ? "压缩冗余，直达意图，节省 token" : "Compress to core intent, save tokens",
                zh ? "我觉得就是字体有点小了看着费劲" : "I think font is kinda small and hard to read",
                zh ? "字体太小。" : "Font too small."
            )
        case "structured":
            return (
                zh ? "多步骤口语转有序列表（实验性）" : "Multi-step → numbered list (experimental)",
                zh ? "改颜色加字段写测试" : "Fix color, add field, write tests",
                zh ? "1. 改颜色\n2. 加字段\n3. 写测试" : "1. Fix color\n2. Add field\n3. Write tests"
            )
        default:
            return nil
        }
    }

    var body: some View {
        if style == "custom" {
            VStack(alignment: .leading, spacing: 4) {
                Text(zh ? "自定义润色指令" : "Custom polish prompt")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                TextEditor(text: $customPrompt)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                Text(zh ? "描述你希望如何处理语音转写文本" : "Describe how you want the transcript processed")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.leading, 30)
        } else if let info {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Spacer()
                    Text(info.desc)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { showExample.toggle() }
                    } label: {
                        Image(systemName: showExample ? "xmark.circle.fill" : "questionmark.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                if showExample {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(zh ? "语音原文" : "Voice input")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.tertiary)
                            Text(info.before)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(zh ? "润色结果" : "Polished")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.accentColor.opacity(0.7))
                            Text(info.after)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.06)))
                }
            }
            .padding(.leading, 30)
        }
    }
}

struct SettingsLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.font(.system(size: 15)).foregroundStyle(.primary)
                .frame(width: 22, alignment: .center)
            configuration.title
        }
    }
}
