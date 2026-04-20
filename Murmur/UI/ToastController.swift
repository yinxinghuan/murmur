import AppKit
import SwiftUI

/// A small toast bubble that appears directly below our menubar icon.
@MainActor
final class ToastController {
    static let shared = ToastController()

    private var panel: NSPanel?
    private var hideTimer: Timer?
    private var toastMessage = ToastMessage()

    @Observable
    final class ToastMessage {
        var title: String = ""
        var content: String?
        var icon: String = ""
        var style: ToastStyle = .info
        var actionLabel: String?
        var action: (() -> Void)?
        var actionDone: Bool = false
        var arrowOffset: CGFloat = 140
    }

    enum ToastStyle {
        case success, warning, error, info
    }

    func show(
        _ title: String,
        content: String? = nil,
        icon: String = "info.circle.fill",
        style: ToastStyle = .info,
        duration: TimeInterval = 4.0,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        hideTimer?.invalidate()

        toastMessage.title = title
        toastMessage.content = content
        toastMessage.icon = icon
        toastMessage.style = style
        toastMessage.actionLabel = actionLabel
        toastMessage.action = action
        toastMessage.actionDone = false

        if panel == nil {
            createPanel()
        }

        panel?.ignoresMouseEvents = (action == nil)
        positionPanel()

        panel?.alphaValue = 0
        panel?.orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.panel?.animator().alphaValue = 1
        }

        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hide()
            }
        }
    }

    func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        let panelRef = panel
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panelRef?.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor in
                panelRef?.orderOut(nil)
            }
        })
    }

    // MARK: - Positioning

    private func positionPanel() {
        guard let panel else { return }
        guard let screen = NSScreen.main else { return }

        // Find our status bar item window
        var iconCenterX: CGFloat?
        for window in NSApp.windows {
            let typeName = type(of: window).description()
            if typeName.contains("NSStatusBar") {
                iconCenterX = window.frame.midX
                break
            }
        }

        // Resize panel to fit content
        if let contentView = panel.contentView {
            let fittingSize = contentView.fittingSize
            panel.setContentSize(fittingSize)
        }

        let panelWidth = panel.frame.width
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let menuBarBottom = visibleFrame.maxY

        let centerX = iconCenterX ?? (screenFrame.maxX - 160)
        var x = centerX - panelWidth / 2

        // Keep within screen bounds
        let margin: CGFloat = 8
        x = max(screenFrame.minX + margin, min(x, screenFrame.maxX - panelWidth - margin))

        // Arrow points to icon center, relative to bubble left edge (accounting for 16pt padding)
        let shadowPadding: CGFloat = 16
        toastMessage.arrowOffset = max(20, min(centerX - x - shadowPadding, panelWidth - 2 * shadowPadding - 20))

        let y = menuBarBottom - panel.frame.height
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Panel Creation

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false

        let view = ToastBubbleView(message: toastMessage)
            .fixedSize()
            .padding(16) // Extra space for shadow rendering
        let hostingView = NSHostingView(rootView: view)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        hostingView.layer?.masksToBounds = false
        panel.contentView = hostingView

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        if let contentView = panel.contentView?.superview {
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }

        self.panel = panel
    }
}

// MARK: - Toast Bubble View

private struct ToastBubbleView: View {
    @Bindable var message: ToastController.ToastMessage

    private var iconColor: Color {
        switch message.style {
        case .success: .green
        case .warning: .orange
        case .error:   .red
        case .info:    .secondary
        }
    }

    private let arrowHeight: CGFloat = 8
    private let arrowWidth: CGFloat = 16
    private let cornerRadius: CGFloat = 10

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Text content
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: message.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(iconColor)
                    Text(message.title)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                if let content = message.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 13))
                        .lineLimit(3)
                        .foregroundStyle(.primary)
                        .padding(.top, 6)
                }
            }

            if message.actionLabel != nil, message.action != nil {
                actionButton
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, arrowHeight + 12)
        .padding(.bottom, 12)
        .frame(maxWidth: 280)
        .background(
            BubbleShape(
                cornerRadius: cornerRadius,
                arrowWidth: arrowWidth,
                arrowHeight: arrowHeight,
                arrowOffset: message.arrowOffset
            )
            .fill(Color(nsColor: .windowBackgroundColor))
            .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        )
        .overlay(
            BubbleShape(
                cornerRadius: cornerRadius,
                arrowWidth: arrowWidth,
                arrowHeight: arrowHeight,
                arrowOffset: message.arrowOffset
            )
            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
    }
}

extension ToastBubbleView {
    private var actionButton: some View {
        Button {
            message.action?()
            message.actionDone = true
        } label: {
            Image(systemName: message.actionDone ? "checkmark" : "doc.on.doc")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(message.actionDone ? Color.green : Color.accentColor)
                )
        }
        .buttonStyle(.plain)
        .disabled(message.actionDone)
    }
}

// MARK: - Bubble Shape with Arrow

/// A rounded rectangle with a small upward-pointing arrow at the top.
private struct BubbleShape: InsettableShape {
    let cornerRadius: CGFloat
    let arrowWidth: CGFloat
    let arrowHeight: CGFloat
    let arrowOffset: CGFloat
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> BubbleShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let bodyTop = r.minY + arrowHeight
        let cr = cornerRadius

        // Clamp arrow position
        let minOffset = cr + arrowWidth / 2 + 2
        let maxOffset = r.width - cr - arrowWidth / 2 - 2
        let ao = max(minOffset, min(arrowOffset, maxOffset))

        var path = Path()

        // Start at top-left corner, after the corner radius
        path.move(to: CGPoint(x: r.minX + cr, y: bodyTop))

        // Top edge → arrow
        path.addLine(to: CGPoint(x: r.minX + ao - arrowWidth / 2, y: bodyTop))
        path.addLine(to: CGPoint(x: r.minX + ao, y: r.minY))
        path.addLine(to: CGPoint(x: r.minX + ao + arrowWidth / 2, y: bodyTop))

        // Top edge → top-right corner
        path.addLine(to: CGPoint(x: r.maxX - cr, y: bodyTop))
        path.addArc(center: CGPoint(x: r.maxX - cr, y: bodyTop + cr),
                    radius: cr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)

        // Right edge → bottom-right corner
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - cr))
        path.addArc(center: CGPoint(x: r.maxX - cr, y: r.maxY - cr),
                    radius: cr, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

        // Bottom edge → bottom-left corner
        path.addLine(to: CGPoint(x: r.minX + cr, y: r.maxY))
        path.addArc(center: CGPoint(x: r.minX + cr, y: r.maxY - cr),
                    radius: cr, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)

        // Left edge → top-left corner
        path.addLine(to: CGPoint(x: r.minX, y: bodyTop + cr))
        path.addArc(center: CGPoint(x: r.minX + cr, y: bodyTop + cr),
                    radius: cr, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        path.closeSubpath()
        return path
    }
}
