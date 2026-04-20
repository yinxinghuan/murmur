import SwiftUI

struct AppStyleRulesView: View {
    @Binding var rules: [String: String]
    let zh: Bool
    @State private var showingAppPicker = false

    private let styleOptions: [(value: String, labelZh: String, labelEn: String)] = [
        ("spoken",     "口语",    "Spoken"),
        ("natural",    "自然",    "Natural"),
        ("concise",    "精简",    "Concise"),
        ("structured", "结构化",  "Structured"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Existing rules
            if !rules.isEmpty {
                ForEach(sortedRules, id: \.key) { bundleId, style in
                    HStack(spacing: 8) {
                        if let icon = appIcon(for: bundleId) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 18, height: 18)
                        }
                        Text(appName(for: bundleId))
                            .font(.system(size: 12))
                            .lineLimit(1)

                        Spacer()

                        Picker("", selection: Binding(
                            get: { style },
                            set: { rules[bundleId] = $0 }
                        )) {
                            ForEach(styleOptions, id: \.value) { opt in
                                Text(zh ? opt.labelZh : opt.labelEn).tag(opt.value)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 90)

                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                rules[bundleId] = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            }

            // Add button
            Button {
                showingAppPicker = true
            } label: {
                Label(zh ? "添加应用规则" : "Add App Rule", systemImage: "plus.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingAppPicker) {
                AppPickerPopover(rules: $rules, zh: zh, styleOptions: styleOptions)
            }

            Text(zh ? "在指定应用中录音时自动切换润色风格" : "Auto-switch polish style when recording in specific apps")
                .font(.caption2).foregroundStyle(.tertiary)
        }
    }

    private var sortedRules: [(key: String, value: String)] {
        rules.sorted { appName(for: $0.key) < appName(for: $1.key) }
    }

    private func appName(for bundleId: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return FileManager.default.displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
        }
        // Fallback: extract last component of bundle ID
        return bundleId.components(separatedBy: ".").last ?? bundleId
    }

    private func appIcon(for bundleId: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

// MARK: - App Picker Popover

private struct AppPickerPopover: View {
    @Binding var rules: [String: String]
    let zh: Bool
    let styleOptions: [(value: String, labelZh: String, labelEn: String)]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var runningApps: [(name: String, bundleId: String, icon: NSImage?)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .filter { !rules.keys.contains($0.bundleIdentifier!) }
            .map { app in
                let name = app.localizedName ?? app.bundleIdentifier ?? "?"
                let icon = app.icon
                return (name: name, bundleId: app.bundleIdentifier!, icon: icon)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var filteredApps: [(name: String, bundleId: String, icon: NSImage?)] {
        if searchText.isEmpty { return runningApps }
        let q = searchText.lowercased()
        return runningApps.filter {
            $0.name.lowercased().contains(q) || $0.bundleId.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 11))
                TextField(zh ? "搜索应用..." : "Search apps...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(8)

            Divider()

            if filteredApps.isEmpty {
                Text(zh ? "没有可添加的应用" : "No apps to add")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .padding(20)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredApps, id: \.bundleId) { app in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    rules[app.bundleId] = "natural"
                                }
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    if let icon = app.icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                    }
                                    Text(app.name)
                                        .font(.system(size: 12))
                                    Spacer()
                                    Text(app.bundleId)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.quaternary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(width: 320, height: 240)
    }
}
