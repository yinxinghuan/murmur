import AppKit
import CoreGraphics
import ApplicationServices
import UserNotifications

final class TextInjector: @unchecked Sendable {

    enum PasteResult {
        case success(appName: String)
        case focusLost(targetAppName: String)
    }

    /// Copy text to the system clipboard
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Paste text into the target app, with result callback
    func pasteText(_ text: String, targetApp: NSRunningApplication? = nil, completion: (@Sendable (PasteResult) -> Void)? = nil) {
        // Filter junk
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty || cleaned.hasPrefix("[BLANK") {
            owLog("[TextInjector] Skipping empty/junk text: \(cleaned)")
            return
        }

        owLog("[TextInjector] Starting paste (\(cleaned.count) chars)")

        // Always put text on clipboard first
        copyToClipboard(cleaned)

        // Activate the target app
        let targetName = targetApp?.localizedName ?? "unknown"
        let targetPid = targetApp?.processIdentifier
        if let app = targetApp {
            owLog("[TextInjector] Activating: \(app.localizedName ?? "?") (pid \(app.processIdentifier))")
            app.activate()
        }

        // Wait for app to come to front, then paste via CGEvent
        let delay: TimeInterval = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            let frontmost = NSWorkspace.shared.frontmostApplication
            let frontmostPid = frontmost?.processIdentifier
            owLog("[TextInjector] Frontmost at paste time: \(frontmost?.localizedName ?? "none") (pid \(frontmostPid ?? 0))")
            owLog("[TextInjector] AXIsProcessTrusted: \(AXIsProcessTrusted())")

            // Check if target app is still in focus
            let focusMatch = (targetPid != nil && targetPid == frontmostPid)

            if focusMatch {
                owLog("[TextInjector] Posting CGEvent Cmd+V...")
                self.simulateCmdV()
                completion?(.success(appName: targetName))
            } else {
                owLog("[TextInjector] Focus lost! Target: \(targetName) (pid \(targetPid ?? 0)), Frontmost: \(frontmost?.localizedName ?? "?") (pid \(frontmostPid ?? 0))")
                // Don't send Cmd+V to wrong app — text is in clipboard as fallback
                completion?(.focusLost(targetAppName: targetName))
            }
        }
    }

    /// Simulate Cmd+V via CGEvent
    private func simulateCmdV() {
        let vKeyCode: CGKeyCode = 9

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) else {
            owLog("[TextInjector] CGEvent creation failed!")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        usleep(80_000)
        keyUp.post(tap: .cghidEventTap)
        owLog("[TextInjector] CGEvent Cmd+V posted")
    }
}
