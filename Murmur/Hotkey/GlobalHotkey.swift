import Cocoa
import ApplicationServices

final class GlobalHotkey {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isPressed = false

    // Right Option key = keyCode 61
    private let targetKeyCode: UInt16 = 61

    private let onPress: () -> Void
    private let onRelease: () -> Void
    private let onCancel: () -> Void

    init(onPress: @escaping () -> Void, onRelease: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onPress = onPress
        self.onRelease = onRelease
        self.onCancel = onCancel
    }

    /// Check and optionally prompt for Accessibility permissions.
    /// Uses a real functional test (AXUIElement) instead of trusting AXIsProcessTrusted(),
    /// which can return stale results with ad-hoc or self-signed binaries.
    static func checkAccessibility(prompt: Bool) -> Bool {
        // Real test: try to get the focused element via AXUIElement API.
        // This only works if Accessibility is truly granted.
        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )
        // .success or .noValue both mean we have access
        // .apiDisabled or .cannotComplete means no access
        if result == .success || result == .noValue {
            owLog("[GlobalHotkey] Accessibility real test: PASS (AXUIElement result=\(result.rawValue))")
            return true
        }

        // Also check the official API
        if AXIsProcessTrusted() {
            owLog("[GlobalHotkey] AXIsProcessTrusted=true (but AXUIElement failed with \(result.rawValue))")
            return true
        }

        owLog("[GlobalHotkey] Accessibility NOT granted (AXUIElement=\(result.rawValue), AXIsProcessTrusted=false)")

        // Not granted — show prompt if requested
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
        return false
    }

    /// Register global and local key monitors for Right Option hold-to-talk + Esc cancel
    func register() {
        // Monitor events in other applications
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            if event.type == .flagsChanged {
                self?.handleFlagsChanged(event)
            } else if event.type == .keyDown {
                self?.handleKeyDown(event)
            }
        }

        // Monitor events in our own app
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            if event.type == .flagsChanged {
                self?.handleFlagsChanged(event)
            } else if event.type == .keyDown {
                self?.handleKeyDown(event)
            }
            return event
        }
    }

    func unregister() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    // Esc key = keyCode 53
    private func handleKeyDown(_ event: NSEvent) {
        if event.keyCode == 53 {
            onCancel()
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        // Only respond to Right Option key
        guard event.keyCode == targetKeyCode else { return }

        let optionPressed = event.modifierFlags.contains(.option)

        if optionPressed && !isPressed {
            isPressed = true
            onPress()
        } else if !optionPressed && isPressed {
            isPressed = false
            onRelease()
        }
    }

    deinit {
        unregister()
    }
}
