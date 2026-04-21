import SwiftUI

struct MenuBarDropdownView: View {
    @Environment(AppState.self) var appState

    private var zh: Bool { appState.uiLanguage == "zh" }

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 10) {

            // ── Header ──
            Button(action: { PreferencesWindowController.shared.show() }) {
                HStack(spacing: 10) {
                    MurmurLogo(color: Color.primary).frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Murmur").font(.system(size: 16, weight: .semibold))
                        statusText
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()

            // ── Quick Controls ──
            HStack {
                Label(zh ? "文本润色" : "Text Polish", systemImage: "sparkle")
                    .labelStyle(SettingsLabelStyle())
                Spacer()
                if appState.llmCleanupEnabled {
                    Text(appState.ollamaAvailable ? (zh ? "已连接" : "OK") : (zh ? "未连接" : "Off"))
                        .font(.caption2)
                        .foregroundStyle(appState.ollamaAvailable ? Color.secondary : Color.orange)
                }
                Toggle("", isOn: $appState.llmCleanupEnabled)
                    .toggleStyle(.switch).labelsHidden().controlSize(.mini)
                    .disabled(appState.translateToEnglish)
            }

            // ── Recent Transcriptions ──
            if !appState.transcriptionHistory.isEmpty {
                Divider()
                Text(zh ? "最近转写" : "Recent")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)

                ForEach(appState.transcriptionHistory.prefix(5)) { record in
                    HistoryRowButton(record: record) {
                        appState.copyHistoryItem(record)
                    }
                }
            }

            Divider()

            // ── Open Main Window ──
            Button(action: { PreferencesWindowController.shared.show() }) {
                HStack {
                    Label(zh ? "打开 Murmur" : "Open Murmur", systemImage: "macwindow")
                        .labelStyle(SettingsLabelStyle())
                    Spacer()
                    Text("⌘,")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // ── Quit ──
            HStack {
                Label(zh ? "退出 Murmur" : "Quit Murmur", systemImage: "xmark.circle")
                    .labelStyle(SettingsLabelStyle())
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
            .contentShape(Rectangle())
            .onTapGesture { NSApplication.shared.terminate(nil) }
        }
        .padding(14)
        .frame(width: 300)
        .onAppear {
            appState.refreshPermissions()
            Task {
                await appState.refreshOllamaStatus()
                await appState.checkForUpdate()
            }
        }
    }

}

private struct HistoryRowButton: View {
    let record: AppState.TranscriptionRecord
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(record.cleaned)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)
                Spacer(minLength: 4)
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10))
                    .foregroundStyle(isHovered ? .secondary : .quaternary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private extension MenuBarDropdownView {
    @ViewBuilder
    var statusText: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(appState.modelLoaded ? Color.green.opacity(0.8)
                      : (appState.modelLoading ? Color.blue.opacity(0.6) : Color.orange.opacity(0.7)))
                .frame(width: 6, height: 6)
            if appState.modelLoading {
                Text("\(zh ? "加载中" : "Loading") \(Int(appState.modelLoadProgress * 100))%")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else if appState.modelLoaded {
                Text(zh ? "就绪" : "Ready")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                Text(zh ? "未加载" : "No model")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
