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

    private var zh: Bool { appState.uiLanguage == "zh" }

    var body: some View {
        @Bindable var appState = appState

        HStack(spacing: 0) {
            // ── Sidebar ──
            VStack(spacing: 4) {
                // Logo
                HStack(spacing: 8) {
                    MurmurLogo(color: .primary).frame(width: 24, height: 24)
                    Text("Murmur")
                        .font(.system(size: 15, weight: .semibold))
                }
                .padding(.bottom, 20)

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

                Text("v\(AppState.currentVersion)")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .frame(width: 140)
            .background(Color.primary.opacity(0.02))

            // Separator
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(width: 1)

            // ── Content ──
            Group {
                switch selectedTab {
                case .home: HomeTab()
                case .history: HistoryTab()
                case .settings: SettingsContainerTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 700, height: 560)
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
        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab } }) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                Text(tab.label(zh: zh))
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
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
    }
}
