import SwiftUI

struct GeneralSettingsTab: View {
    @Environment(AppState.self) var appState

    private var zh: Bool { appState.uiLanguage == "zh" }
    @State private var showDeleteConfirm = false

    var body: some View {
        @Bindable var appState = appState

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // ── Speech Recognition ──
                settingsCard(zh ? "语音识别" : "Speech Recognition") {
                    settingsRow(zh ? "语音模型" : "Model", icon: "waveform") {
                        HStack(spacing: 6) {
                            Picker("", selection: $appState.whisperModel) {
                                ForEach(whisperModels, id: \.name) { m in
                                    Text(m.displayLabel(
                                        downloaded: appState.downloadedWhisperModels.contains(m.name),
                                        recommended: m.name == recommendedModel, zh: zh
                                    )).tag(m.name)
                                }
                            }
                            .labelsHidden()
                            .id(appState.downloadedWhisperModels)
                            .onChange(of: appState.whisperModel) { Task { await appState.loadModel() } }
                            if appState.downloadedWhisperModels.contains(appState.whisperModel) && !appState.modelLoading {
                                Button(action: { showDeleteConfirm = true }) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.secondary)
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.plain)
                                .help(zh ? "删除当前模型" : "Delete current model")
                                .alert(
                                    zh ? "删除模型" : "Delete Model",
                                    isPresented: $showDeleteConfirm
                                ) {
                                    Button(zh ? "删除" : "Delete", role: .destructive) {
                                        appState.deleteWhisperModel(name: appState.whisperModel)
                                    }
                                    Button(zh ? "取消" : "Cancel", role: .cancel) {}
                                } message: {
                                    Text(zh ? "确定要删除 \(appState.whisperModel) 吗？下次使用需要重新下载。" : "Delete \(appState.whisperModel)? You'll need to re-download it next time.")
                                }
                            }
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
                    }
                    modelStatus

                    settingsRow(zh ? "输入语言" : "Input Language", icon: "globe") {
                        Picker("", selection: $appState.language) {
                            Text(zh ? "自动检测" : "Auto").tag("")
                            Text("中文").tag("zh")
                            Text("English").tag("en")
                            Text("日本語").tag("ja")
                            Text("한국어").tag("ko")
                            Text("Español").tag("es")
                            Text("Français").tag("fr")
                            Text("Deutsch").tag("de")
                            Text("Italiano").tag("it")
                            Text("Português").tag("pt")
                            Text("Русский").tag("ru")
                            Text("العربية").tag("ar")
                            Text("हिन्दी").tag("hi")
                            Text("Türkçe").tag("tr")
                            Text("Polski").tag("pl")
                            Text("Nederlands").tag("nl")
                            Text("Svenska").tag("sv")
                            Text("Dansk").tag("da")
                            Text("Norsk").tag("no")
                            Text("Suomi").tag("fi")
                            Text("Čeština").tag("cs")
                            Text("Română").tag("ro")
                            Text("Magyar").tag("hu")
                            Text("Ελληνικά").tag("el")
                            Text("עברית").tag("he")
                            Text("ภาษาไทย").tag("th")
                            Text("Tiếng Việt").tag("vi")
                            Text("Bahasa Indonesia").tag("id")
                            Text("Bahasa Melayu").tag("ms")
                            Text("Українська").tag("uk")
                        }
                        .labelsHidden()
                    }

                    if appState.language == "zh" || appState.language == "" {
                        settingsRow(zh ? "中文格式" : "Chinese Format", icon: "character") {
                            Picker("", selection: $appState.chineseVariant) {
                                Text(zh ? "简体" : "简").tag("simplified")
                                Text(zh ? "繁體" : "繁").tag("traditional")
                                Text(zh ? "不转换" : "Auto").tag("auto")
                            }
                            .labelsHidden().pickerStyle(.segmented)
                            .disabled(appState.translateToEnglish)
                        }
                    }

                    if appState.language != "en" && appState.whisperModel != "small.en" {
                        settingsRow(zh ? "翻译输出" : "Translate", icon: "character.bubble") {
                            Picker("", selection: $appState.translateToEnglish) {
                                Text(zh ? "原文" : "Off").tag(false)
                                Text(zh ? "译为英文" : "→ EN").tag(true)
                            }
                            .labelsHidden().pickerStyle(.segmented)
                        }
                    }
                }

                // ── Input ──
                settingsCard(zh ? "输入" : "Input") {
                    settingsRow(zh ? "快捷键" : "Hotkey", icon: "command") {
                        Text("Right ⌥")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor))
                    }

                    settingsRow(zh ? "录音方式" : "Mode", icon: "hand.tap") {
                        Picker("", selection: $appState.dictationMode) {
                            Text(zh ? "按住" : "Hold").tag("hold")
                            Text(zh ? "切换" : "Toggle").tag("toggle")
                        }
                        .labelsHidden().pickerStyle(.segmented)
                    }

                    settingsRow(zh ? "自动粘贴" : "Auto-paste", icon: "doc.on.clipboard") {
                        Toggle("", isOn: $appState.autoPasteEnabled)
                            .toggleStyle(.switch).labelsHidden().controlSize(.small)
                    }
                }

                // ── Appearance ──
                settingsCard(zh ? "外观" : "Appearance") {
                    settingsRow(zh ? "悬浮条" : "Flow Bar", icon: "capsule") {
                        Picker("", selection: $appState.flowBarTheme) {
                            Text(zh ? "黑底" : "Dark").tag("voiceFirst")
                            Text(zh ? "白底" : "Light").tag("invert")
                        }
                        .labelsHidden().pickerStyle(.segmented)
                    }

                    settingsRow(zh ? "开机启动" : "Launch at Login", icon: "power") {
                        Toggle("", isOn: $appState.launchAtLogin)
                            .toggleStyle(.switch).labelsHidden().controlSize(.small)
                    }
                }
            }
            .padding(28)
        }
    }

    // MARK: - Layout Helpers

    private func settingsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    private func settingsRow<Content: View>(_ label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Label {
                Text(label).font(.system(size: 13))
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }
            Spacer()
            content()
                .frame(minWidth: 160, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Model Status

    @ViewBuilder
    private var modelStatus: some View {
        if appState.modelLoading {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if appState.modelLoadPhase == "compile" {
                        Text(zh ? "编译模型…" : "Compiling…")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    } else if appState.modelLoadPhase == "download" {
                        Text(zh ? "下载中…" : "Downloading…")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    ProgressView(value: appState.modelLoadProgress).frame(maxWidth: .infinity)
                    Text("\(Int(appState.modelLoadProgress * 100))%")
                        .font(.caption).foregroundStyle(.secondary).frame(width: 32, alignment: .trailing)
                    Button {
                        appState.cancelModelLoad()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(zh ? "取消" : "Cancel")
                }
                if appState.modelLoadPhase == "compile" {
                    Text(zh ? "首次加载需要编译，可能需要 1-2 分钟" : "First load requires compilation, may take 1-2 min")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
            }
            .padding(.vertical, 4)
            .padding(.leading, 28)
        } else if let failed = appState.failedModelName {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange).font(.system(size: 11))
                Text(zh ? "\(failed) 下载不完整" : "\(failed) incomplete")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
                Button(zh ? "重新下载" : "Re-download") { appState.retryModelDownload() }
                    .buttonStyle(.borderedProminent).controlSize(.small)
            }
            .padding(.vertical, 4)
            .padding(.leading, 28)
        } else if !appState.modelLoaded {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange).font(.system(size: 11))
                Text(zh ? "模型未加载" : "No model").font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
                Button(zh ? "下载" : "Download") { Task { await appState.loadModel() } }
                    .buttonStyle(.bordered).controlSize(.small)
            }
            .padding(.vertical, 4)
            .padding(.leading, 28)
        }
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
}
