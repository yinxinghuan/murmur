import SwiftUI

struct HistoryTab: View {
    @Environment(AppState.self) var appState

    private var zh: Bool { appState.uiLanguage == "zh" }
    @State private var searchText = ""
    @State private var expandedId: UUID?

    private var filteredHistory: [AppState.TranscriptionRecord] {
        if searchText.isEmpty { return appState.transcriptionHistory }
        let query = searchText.lowercased()
        return appState.transcriptionHistory.filter {
            $0.cleaned.lowercased().contains(query) || $0.raw.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Toolbar ──
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 12))
                    TextField(zh ? "搜索..." : "Search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                )

                if !appState.transcriptionHistory.isEmpty {
                    Button(action: { appState.clearHistory() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(zh ? "清空全部" : "Clear all")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            Divider()

            // ── Content ──
            if filteredHistory.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: appState.transcriptionHistory.isEmpty ? "waveform" : "magnifyingglass")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.quaternary)
                    Text(appState.transcriptionHistory.isEmpty
                         ? (zh ? "暂无转写记录" : "No transcriptions yet")
                         : (zh ? "无匹配结果" : "No matches"))
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                    if appState.transcriptionHistory.isEmpty {
                        Text(zh ? "按住 Right ⌥ 开始录音" : "Hold Right ⌥ to start")
                            .font(.system(size: 12))
                            .foregroundStyle(.quaternary)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredHistory) { record in
                            historyRow(record)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            }

            // ── Footer ──
            Divider()
            HStack {
                Text(zh
                     ? "\(appState.transcriptionHistory.count) 条记录"
                     : "\(appState.transcriptionHistory.count) records")
                    .font(.system(size: 11))
                    .foregroundStyle(.quaternary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
    }

    private func historyRow(_ record: AppState.TranscriptionRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.cleaned)
                        .font(.system(size: 13))
                        .lineLimit(expandedId == record.id ? nil : 2)
                    Text(formatDate(record.date))
                        .font(.system(size: 11))
                        .foregroundStyle(.quaternary)
                }

                Spacer(minLength: 4)

                HStack(spacing: 4) {
                    if record.raw != record.cleaned {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                expandedId = expandedId == record.id ? nil : record.id
                            }
                        }) {
                            Image(systemName: expandedId == record.id ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .help(zh ? "查看原文" : "Show raw")
                    }

                    Button(action: { appState.copyHistoryItem(record) }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .help(zh ? "复制" : "Copy")

                    Button(action: { appState.deleteHistoryItem(record) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundStyle(.quaternary)
                    }
                    .buttonStyle(.plain)
                    .help(zh ? "删除" : "Delete")
                }
                .padding(.top, 2)
            }

            if expandedId == record.id && record.raw != record.cleaned {
                VStack(alignment: .leading, spacing: 4) {
                    Text(zh ? "原文" : "Raw")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.quaternary)
                    Text(record.raw)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.03))
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = zh ? "昨天 HH:mm" : "'Yesterday' HH:mm"
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
        }
        return formatter.string(from: date)
    }
}
