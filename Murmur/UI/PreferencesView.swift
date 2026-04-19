import SwiftUI

enum MainTab: String, CaseIterable {
    case home, history, settings

    var icon: String {
        switch self {
        case .home: return "house"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gear"
        }
    }

    func label(zh: Bool) -> String {
        switch self {
        case .home: return zh ? "主页" : "Home"
        case .history: return zh ? "历史" : "History"
        case .settings: return zh ? "设置" : "Settings"
        }
    }
}

struct MainWindowView: View {
    @Environment(AppState.self) var appState
    @State private var selectedTab: MainTab = .home
    @State private var settingsSubTab: SettingsContainerTab.SettingsSection = .general

    private var zh: Bool { appState.uiLanguage == "zh" }

    var body: some View {
        @Bindable var appState = appState

        HStack(spacing: 0) {
            // ── Sidebar ──
            VStack(spacing: 4) {
                // Logo
                HStack(spacing: 10) {
                    MurmurLogo(color: .primary).frame(width: 44, height: 44)
                    Text("Murmur")
                        .font(.system(size: 20, weight: .semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 24)

                ForEach(MainTab.allCases, id: \.self) { tab in
                    sidebarButton(tab)
                }

                Spacer()

                // Language
                Picker("", selection: $appState.uiLanguage) {
                    Text("中").tag("zh")
                    Text("EN").tag("en")
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 72)

                HStack(spacing: 4) {
                    Text("v\(AppState.currentVersion)")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                    if let latest = appState.latestVersion {
                        Button(action: {
                            NSWorkspace.shared.open(URL(string: "https://github.com/yinxinghuan/murmur/releases/latest")!)
                        }) {
                            Text(zh ? "有更新" : "Update")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 16)
            .frame(width: 200)
            .background(Color.primary.opacity(0.03))

            // Separator
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(width: 1)

            // ── Content ──
            Group {
                switch selectedTab {
                case .home: HomeTab(onNavigate: { selectedTab = $0 }, onNavigateSettings: { settingsSubTab = $0; selectedTab = .settings })
                case .history: HistoryTab()
                case .settings: SettingsContainerTab(initialSection: settingsSubTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 820, minHeight: 620)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func sidebarButton(_ tab: MainTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                if tab == .settings { settingsSubTab = .general }
                selectedTab = tab
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                Text(tab.label(zh: zh))
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTab == tab ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .foregroundStyle(selectedTab == tab ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Container (General + Advanced)

struct SettingsContainerTab: View {
    @Environment(AppState.self) var appState
    var initialSection: SettingsSection = .general
    @State private var settingsSection: SettingsSection = .general

    private var zh: Bool { appState.uiLanguage == "zh" }

    enum SettingsSection: String, CaseIterable {
        case general, advanced

        func label(zh: Bool) -> String {
            switch self {
            case .general: return zh ? "通用" : "General"
            case .advanced: return zh ? "高级" : "Advanced"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section switcher
            HStack(spacing: 0) {
                ForEach(SettingsSection.allCases, id: \.self) { section in
                    Button(action: { settingsSection = section }) {
                        Text(section.label(zh: zh))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(settingsSection == section ? .primary : .tertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                settingsSection == section
                                    ? Capsule().fill(Color.primary.opacity(0.06))
                                    : Capsule().fill(Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)

            // Content
            switch settingsSection {
            case .general: GeneralSettingsTab()
            case .advanced: AdvancedSettingsTab()
            }
        }
        .onChange(of: initialSection) { settingsSection = initialSection }
        .onAppear { settingsSection = initialSection }
    }
}
