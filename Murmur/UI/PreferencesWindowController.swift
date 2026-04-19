import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController {
    static let shared = PreferencesWindowController()

    private var window: NSWindow?
    private var windowDelegate: WindowDelegate?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            // Only switch policy if needed
            if NSApp.activationPolicy() != .regular {
                NSApp.setActivationPolicy(.regular)
            }
            return
        }
        createWindow()
    }

    func close() {
        window?.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    private func createWindow() {
        let mainView = MainWindowView()
            .environment(AppState.shared)

        let hostingView = NSHostingView(rootView: mainView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Murmur"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 820, height: 620)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)

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
        // Delay policy switch to avoid menu bar flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
