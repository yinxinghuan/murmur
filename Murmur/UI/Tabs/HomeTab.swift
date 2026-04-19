import SwiftUI

struct HomeTab: View {
    @Environment(AppState.self) var appState
    var onNavigate: ((MainTab) -> Void)?
    var onNavigateSettings: ((SettingsContainerTab.SettingsSection) -> Void)?

    private var zh: Bool { appState.uiLanguage == "zh" }

    private var todayRecords: [AppState.TranscriptionRecord] {
        appState.transcriptionHistory.filter { Calendar.current.isDateInToday($0.date) }
    }
    private var todayCount: Int { todayRecords.count }
    private var todayWords: Int {
        todayRecords.reduce(0) { $0 + $1.cleaned.count }
    }
    private var totalCount: Int { appState.transcriptionHistory.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                // ── Hero ──
                VStack(alignment: .leading, spacing: 12) {
                    Text(zh ? "用声音\n输入文字，只在这台 Mac" : "Voice to Text\nOnly on This Mac")
                        .font(.system(size: 34, weight: .regular))
                        .lineSpacing(4)

                    Text(zh ? "本地处理 · 按住 Right ⌥ 说话，松开自动粘贴" : "Local processing · Hold Right ⌥ to speak, release to paste")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    // Status pills (clickable → navigate to settings)
                    HStack(spacing: 8) {
                        Button(action: { onNavigateSettings?(.general) }) {
                            statusPillContent(
                                icon: "waveform",
                                label: appState.modelLoaded
                                    ? appState.whisperModel.replacingOccurrences(of: "_", with: " ")
                                    : (zh ? "模型未加载" : "No model"),
                                color: appState.modelLoaded ? .green : (appState.modelLoading ? .blue : .orange),
                                loading: appState.modelLoading ? appState.modelLoadProgress : nil
                            )
                        }
                        .buttonStyle(.plain)
                        Button(action: { onNavigateSettings?(.advanced) }) {
                            statusPillContent(
                                icon: "sparkle",
                                label: !appState.llmCleanupEnabled ? (zh ? "润色关闭" : "Polish off")
                                    : (appState.ollamaAvailable ? "Ollama" : (zh ? "未连接" : "Offline")),
                                color: !appState.llmCleanupEnabled ? Color.primary.opacity(0.3)
                                    : (appState.ollamaAvailable ? .green : .orange)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 8)

                // ── Stats ──
                HStack(spacing: 12) {
                    StatCard(
                        value: "\(todayCount)",
                        label: zh ? "今日转写" : "Today",
                        subtitle: zh ? "次语音输入" : "voice inputs",
                        tintLight: Color(hue: 0.45, saturation: 0.12, brightness: 0.95),
                        tintDark: Color(hue: 0.45, saturation: 0.25, brightness: 0.22)
                    ) { onNavigate?(.history) }
                    StatCard(
                        value: "\(todayWords)",
                        label: zh ? "今日字数" : "Words",
                        subtitle: zh ? "个字符已转写" : "characters transcribed",
                        tintLight: Color(hue: 0.75, saturation: 0.10, brightness: 0.95),
                        tintDark: Color(hue: 0.75, saturation: 0.20, brightness: 0.22)
                    ) { onNavigate?(.history) }
                    StatCard(
                        value: "\(totalCount)",
                        label: zh ? "全部记录" : "Total",
                        subtitle: zh ? "条历史记录" : "total records",
                        tintLight: Color(hue: 0.12, saturation: 0.10, brightness: 0.96),
                        tintDark: Color(hue: 0.12, saturation: 0.20, brightness: 0.22)
                    ) { onNavigate?(.history) }
                }

                // ── Recent ──
                if !appState.transcriptionHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(zh ? "最近转写" : "Recent")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.tertiary)

                        VStack(spacing: 0) {
                            ForEach(Array(appState.transcriptionHistory.prefix(5).enumerated()), id: \.element.id) { index, record in
                                if index > 0 {
                                    Divider().padding(.horizontal, 16)
                                }
                                HomeHistoryRow(record: record) {
                                    appState.copyHistoryItem(record)
                                }
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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)

                    HStack(spacing: 10) {
                        shortcutCard(key: "⌥", desc: zh ? "按住说话" : "Hold to talk")
                        shortcutCard(key: "Esc", desc: zh ? "取消" : "Cancel")
                        shortcutCard(key: "⌘,", desc: zh ? "设置" : "Settings")
                    }
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Status Pill

    private func statusPillContent(icon: String, label: String, color: Color, loading: Double? = nil) -> some View {
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

    // MARK: - Shortcut Card

    private func shortcutCard(key: String, desc: String) -> some View {
        VStack(spacing: 10) {
            Text(key)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .frame(width: 44, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.06))
                )
            Text(desc)
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.primary.opacity(0.04), lineWidth: 1)
                )
        )
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let subtitle: String
    let tintLight: Color
    let tintDark: Color
    @Environment(\.colorScheme) var colorScheme
    private var tint: Color { colorScheme == .dark ? tintDark : tintLight }
    var action: (() -> Void)?
    @State private var isHovered = false

    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isHovered ? .primary : .secondary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 100)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(isHovered ? tint.opacity(0.85) : tint)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - History Row

private struct HomeHistoryRow: View {
    let record: AppState.TranscriptionRecord
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(record.cleaned)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)
                Spacer(minLength: 16)
                Text(formatTime(record.date))
                    .font(.system(size: 12))
                    .foregroundStyle(.quaternary)
                    .layoutPriority(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }
}
