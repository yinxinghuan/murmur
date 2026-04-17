import SwiftUI
import AppKit

/// Murmur waveform logo — 5 symmetric bars
struct MurmurLogo: View {
    var color: Color = .white
    var barWidth: CGFloat = 10
    var gap: CGFloat = 3

    // Heights relative to 100x100 viewBox
    private let heights: [CGFloat] = [20, 40, 56, 40, 20]
    private let centerY: CGFloat = 50

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 100
            for i in 0..<5 {
                let h = heights[i]
                let x = 20 + CGFloat(i) * (barWidth + gap)
                let y = centerY - h / 2
                let rect = CGRect(
                    x: x * scale,
                    y: y * scale,
                    width: barWidth * scale,
                    height: h * scale
                )
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2 * scale)
                context.fill(path, with: .color(color))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Menu bar icon using the waveform logo
struct MenuBarIcon: View {
    let state: AppState.RecordingState

    var body: some View {
        Image(nsImage: renderMenuBarImage(recording: state == .recording))
    }

    private func renderMenuBarImage(recording: Bool) -> NSImage {
        let size = NSSize(width: recording ? 24 : 18, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            // Draw waveform bars
            let barWidth: CGFloat = 2
            let gap: CGFloat = 1.5
            let heights: [CGFloat] = [4, 8, 12, 8, 4]
            let totalWidth = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * gap
            let startX = recording ? 0.0 : (rect.width - totalWidth) / 2

            NSColor.white.setFill()  // Template image uses white
            for (i, h) in heights.enumerated() {
                let x = startX + CGFloat(i) * (barWidth + gap)
                let y = (rect.height - h) / 2
                let path = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: barWidth, height: h), xRadius: 1, yRadius: 1)
                path.fill()
            }

            // Red dot when recording
            if recording {
                NSColor.red.setFill()
                let dotSize: CGFloat = 5
                let dotX = totalWidth + 4
                let dotY = (rect.height - dotSize) / 2
                let dot = NSBezierPath(ovalIn: NSRect(x: dotX, y: dotY, width: dotSize, height: dotSize))
                dot.fill()
            }

            return true
        }
        image.isTemplate = !recording  // Template mode for dark/light menu bar adaptation (not when showing red dot)
        return image
    }

    // Unused but kept for reference
    private var waveformBars: some View {
        HStack(spacing: 1) {
            bar(height: 4)
            bar(height: 8)
            bar(height: 11)
            bar(height: 8)
            bar(height: 4)
        }
    }

    private func bar(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .frame(width: 2, height: height)
    }
}
