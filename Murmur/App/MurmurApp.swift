import SwiftUI
import AppKit
import UserNotifications

func owLog(_ msg: String) {
    let line = "\(Date()): \(msg)\n"
    let path = "/tmp/murmur.log"
    if let fh = FileHandle(forWritingAtPath: path) {
        fh.seekToEndOfFile()
        if let data = line.data(using: .utf8) { fh.write(data) }
        fh.closeFile()
    } else {
        FileManager.default.createFile(atPath: path, contents: line.data(using: .utf8))
    }
}

private func loadMenuBarIcon() -> NSImage {
    // Try resource bundle first (SPM puts processed resources here)
    if let url = Bundle.module.url(forResource: "menubar_icon", withExtension: "png"),
       let img = NSImage(contentsOf: url) {
        img.isTemplate = true
        img.size = NSSize(width: 18, height: 18)
        return img
    }
    // Fallback: create programmatically
    let size = NSSize(width: 18, height: 18)
    let img = NSImage(size: size, flipped: false) { rect in
        let bars: [(CGFloat, CGFloat)] = [(5, 5), (9, 9), (13, 13), (9, 9), (5, 5)]
        let barW: CGFloat = 2
        let gap: CGFloat = 2
        let totalW = CGFloat(bars.count) * barW + CGFloat(bars.count - 1) * gap
        let startX = (rect.width - totalW) / 2
        NSColor.black.setFill()
        for (i, (_, h)) in bars.enumerated() {
            let x = startX + CGFloat(i) * (barW + gap)
            let y = (rect.height - h) / 2
            NSBezierPath(roundedRect: NSRect(x: x, y: y, width: barW, height: h), xRadius: 1, yRadius: 1).fill()
        }
        return true
    }
    img.isTemplate = true
    return img
}

@main
struct MurmurApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarDropdownView()
                .environment(AppState.shared)
        } label: {
            Image(nsImage: loadMenuBarIcon())
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        owLog("applicationDidFinishLaunching called")
        NSApplication.shared.setActivationPolicy(.accessory)

        // Set delegate so notifications show even when app is in foreground
        UNUserNotificationCenter.current().delegate = self

        // Set up Cmd+, shortcut via main menu
        setupMainMenu()

        Task { @MainActor in
            owLog("Starting setup...")
            await AppState.shared.setup()
        }
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let prefsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        appMenu.addItem(prefsItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    @objc private func openPreferences() {
        Task { @MainActor in
            PreferencesWindowController.shared.show()
        }
    }

    // When user clicks app icon in Dock/Launchpad while already running
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        PreferencesWindowController.shared.show()
        return false
    }

    // Show notifications as banners even when the app is active/foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
