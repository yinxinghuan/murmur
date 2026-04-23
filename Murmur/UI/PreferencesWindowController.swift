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

    /// Resize window smoothly (used when transitioning from onboarding to main UI)
    func resizeToMain() {
        guard let window else { return }
        let mainSize = NSSize(width: 820, height: 620)
        window.minSize = mainSize
        let newFrame = NSRect(
            x: window.frame.midX - mainSize.width / 2,
            y: window.frame.midY - mainSize.height / 2,
            width: mainSize.width,
            height: mainSize.height
        )
        window.animator().setFrame(newFrame, display: true)
    }

    private func createWindow() {
        let isOnboarding = AppState.shared.isFirstLaunch
        let size = isOnboarding ? NSSize(width: 640, height: 580) : NSSize(width: 820, height: 620)

        let mainView = MainWindowView()
            .environment(AppState.shared)

        let hostingView = NSHostingView(rootView: mainView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Murmur"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = isOnboarding ? NSSize(width: 520, height: 480) : NSSize(width: 820, height: 620)
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
