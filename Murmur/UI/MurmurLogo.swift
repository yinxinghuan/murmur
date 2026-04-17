import SwiftUI
import AppKit

/// Murmur waveform logo — 5 symmetric bars (for settings panel)
struct MurmurLogo: View {
    var color: Color = .white
    var barWidth: CGFloat = 10
    var gap: CGFloat = 3

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

/// Menu bar label — pure SwiftUI, no NSImage
struct MenuBarLabel: View {
    let recording: Bool

    var body: some View {
        HStack(spacing: 2) {
            HStack(spacing: 1.5) {
                bar(h: 4)
                bar(h: 8)
                bar(h: 12)
                bar(h: 8)
                bar(h: 4)
            }
            if recording {
                Circle()
                    .fill(.red)
                    .frame(width: 5, height: 5)
            }
        }
    }

    private func bar(h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .frame(width: 2.5, height: h)
    }
}
