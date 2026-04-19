import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController {
    static let shared = PreferencesWindowController()

    private var window: NSWindow?
    private var windowDelegate: WindowDelegate?

    func show() {
        if let window {
            NSApp.setActivationPolicy(.regular)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        createWindow()
    }

    func close() {
        window?.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    private func createWindow() {
        let zh = AppState.shared.uiLanguage == "zh"
        let mainView = MainWindowView()
            .environment(AppState.shared)

        let hostingView = NSHostingView(rootView: mainView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Murmur"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        let delegate = WindowDelegate()
        window.delegate = delegate
        self.windowDelegate = delegate
        self.window = window

        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private final class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
