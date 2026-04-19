import SwiftUI

struct AdvancedSettingsTab: View {
    @Environment(AppState.self) var appState

    private var zh: Bool { appState.uiLanguage == "zh" }

    var body: some View {
        @Bindable var appState = appState

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // ── Text Polish ──
                settingsCard(zh ? "文本润色" : "Text Polish") {
                    settingsRow(zh ? "启用润色" : "Enable", icon: "sparkle") {
                        HStack(spacing: 6) {
                            if appState.llmCleanupEnabled && !appState.translateToEnglish {
                                Text(appState.ollamaAvailable ? (zh ? "已连接" : "OK") : (zh ? "未连接" : "Off"))
                                    .font(.system(size: 11))
                                    .foregroundStyle(appState.ollamaAvailable ? Color.green : Color.orange)
                            }
                            Toggle("", isOn: $appState.llmCleanupEnabled)
                                .toggleStyle(.switch).labelsHidden().controlSize(.small)
                                .disabled(appState.translateToEnglish)
                        }
                    }
                    .opacity(appState.translateToEnglish ? 0.4 : 1.0)

                    if appState.llmCleanupEnabled && !appState.translateToEnglish {
                        if !appState.ollamaAvailable {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.orange).font(.system(size: 12))
                                Text(zh ? "请先启动 Ollama" : "Start Ollama first")
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                                Spacer()
                                Button("ollama.com") {
                                    NSWorkspace.shared.open(URL(string: "https://ollama.com")!)
                                }
                                .buttonStyle(.bordered).controlSize(.small)
                            }
                            .padding(.vertical, 4)
                        }

                        settingsRow(zh ? "润色模型" : "LLM Model", icon: "cpu") {
                            HStack(spacing: 6) {
                                Picker("", selection: $appState.llmModel) {
                                    llmModelLabel("qwen2.5:1.5b (986 MB)", name: "qwen2.5:1.5b", recommended: false)
                                    llmModelLabel("qwen2.5:3b (1.9 GB)", name: "qwen2.5:3b", recommended: true)
                                    llmModelLabel("qwen2.5:7b (4.7 GB)", name: "qwen2.5:7b", recommended: false)
                                }
                                .labelsHidden()
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
                                .help(zh ? "打开模型目录" : "Open model folder")
                            }
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
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.leading, 28)
                        }

                        settingsRow(zh ? "润色风格" : "Style", icon: "paintpalette") {
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
                            .labelsHidden()
                            .disabled(!appState.ollamaAvailable)
                        }
                        StyleDescription(style: appState.polishStyle, zh: zh, customPrompt: $appState.customPolishPrompt)
                            .padding(.leading, 28)
                    }
                }

                // ── Protected Terms ──
                if appState.llmCleanupEnabled && !appState.translateToEnglish {
                    settingsCard(zh ? "术语保护" : "Protected Terms") {
                        ProtectedTermsView(terms: $appState.protectedTerms, zh: zh)
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

    private func llmModelLabel(_ label: String, name: String, recommended: Bool = false) -> some View {
        let installed = appState.installedLLMModels.contains(name)
        let zh = appState.uiLanguage == "zh"
        var s = label
        if recommended { s += zh ? " ★推荐" : " ★" }
        if !installed { s += " ⤓" }
        return Text(s).tag(name)
    }
}
