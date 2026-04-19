import SwiftUI

struct HomeTab: View {
    @Environment(AppState.self) var appState

    private var zh: Bool { appState.uiLanguage == "zh" }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // ── Hero ──
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        MurmurLogo(color: .accentColor)
                            .frame(width: 32, height: 32)
                        Text(zh ? "用声音输入文字" : "Voice to Text")
                            .font(.system(size: 22, weight: .bold))
                    }
                    Text(zh ? "按住 Right ⌥ 说话，松开自动粘贴到光标处" : "Hold Right ⌥ to speak, release to auto-paste")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                // ── Status ──
                HStack(spacing: 12) {
                    statusPill(
                        icon: "waveform",
                        label: appState.modelLoaded
                            ? appState.whisperModel.replacingOccurrences(of: "_", with: " ")
                            : (zh ? "模型未加载" : "No model"),
                        color: appState.modelLoaded ? .green : (appState.modelLoading ? .blue : .orange),
                        loading: appState.modelLoading ? appState.modelLoadProgress : nil
                    )
                    statusPill(
                        icon: "sparkle",
                        label: !appState.llmCleanupEnabled ? (zh ? "润色关闭" : "Polish off")
                            : (appState.ollamaAvailable ? "Ollama" : (zh ? "未连接" : "Offline")),
                        color: !appState.llmCleanupEnabled ? Color.primary.opacity(0.3)
                            : (appState.ollamaAvailable ? .green : .orange)
                    )
                }

                // ── Recent ──
                if !appState.transcriptionHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(zh ? "最近转写" : "Recent")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            ForEach(Array(appState.transcriptionHistory.prefix(5).enumerated()), id: \.element.id) { index, record in
                                if index > 0 {
                                    Divider().padding(.leading, 14)
                                }
                                Button(action: { appState.copyHistoryItem(record) }) {
                                    HStack(spacing: 0) {
                                        Text(record.cleaned)
                                            .font(.system(size: 13))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .foregroundStyle(.primary)
                                        Spacer(minLength: 12)
                                        Text(formatTime(record.date))
                                            .font(.system(size: 11))
                                            .foregroundStyle(.quaternary)
                                            .layoutPriority(1)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.primary.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                                )
                        )

                        Text(zh ? "点击即可复制" : "Click to copy")
                            .font(.system(size: 11))
                            .foregroundStyle(.quaternary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                // ── Shortcuts ──
                VStack(alignment: .leading, spacing: 10) {
                    Text(zh ? "快捷键" : "Shortcuts")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    HStack(spacing: 10) {
                        shortcutCard(key: "⌥", desc: zh ? "按住说话" : "Hold to talk")
                        shortcutCard(key: "Esc", desc: zh ? "取消" : "Cancel")
                        shortcutCard(key: "⌘,", desc: zh ? "设置" : "Settings")
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }

    // MARK: - Components

    private func statusPill(icon: String, label: String, color: Color, loading: Double? = nil) -> some View {
        HStack(spacing: 7) {
            Circle().fill(color.opacity(0.7)).frame(width: 6, height: 6)
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            if let loading {
                ProgressView(value: loading)
                    .frame(width: 40)
                Text("\(Int(loading * 100))%")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.03))
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.05), lineWidth: 1))
        )
    }

    private func shortcutCard(key: String, desc: String) -> some View {
        VStack(spacing: 6) {
            Text(key)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .frame(width: 36, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.06))
                )
            Text(desc)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.primary.opacity(0.04), lineWidth: 1)
                )
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }
}
