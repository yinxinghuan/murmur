import SwiftUI

struct FlowBarView: View {
    @Environment(AppState.self) var appState
    @State private var showDoneFlash: Bool = false

    private let teal = Color(red: 0.08, green: 0.72, blue: 0.65)

    var body: some View {
        ZStack {
            switch appState.recordingState {
            case .idle:
                if showDoneFlash {
                    DoneFlashDot()
                } else {
                    IdleDot(modelLoaded: appState.modelLoaded, modelLoading: appState.modelLoading)
                }
            case .recording:
                RecordingPill(
                    audioLevel: appState.audioLevel,
                    duration: appState.recordingDuration,
                    teal: teal
                )
            case .transcribing:
                TranscribingSpinner(teal: teal)
            }
        }
        .background(background)
        .clipShape(Capsule())
        .opacity(appState.recordingState == .idle && !showDoneFlash ? 0.25 : 1.0)
        .animation(.spring(duration: 0.3, bounce: 0.1), value: appState.recordingState)
        .animation(.spring(duration: 0.3, bounce: 0.1), value: showDoneFlash)
        .onChange(of: appState.recordingState) { oldState, newState in
            if oldState == .transcribing && newState == .idle {
                withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                    showDoneFlash = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        showDoneFlash = false
                    }
                }
            }
        }
    }

    private var background: some View {
        ZStack {
            Capsule().fill(.ultraThinMaterial)
            Capsule().fill(Color.black.opacity(0.5))
        }
    }
}

// MARK: - Idle Dot

struct IdleDot: View {
    let modelLoaded: Bool
    let modelLoading: Bool
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(.white.opacity(0.5))
            .frame(width: 6, height: 6)
            .scaleEffect(pulse ? 1.15 : 0.85)
            .opacity(pulse ? 0.6 : 0.3)
            .padding(8)
            .animation(
                .easeInOut(duration: 4.0).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear { pulse = true }
    }
}

// MARK: - Recording Pill

struct RecordingPill: View {
    let audioLevel: Float
    let duration: TimeInterval
    let teal: Color

    private var normalizedLevel: CGFloat {
        CGFloat(min(max(audioLevel * 8, 0), 1.0))
    }

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                BreathingRing(level: normalizedLevel, teal: teal)
            }
            .frame(width: 32, height: 32)

            Text(formatDuration(duration))
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .monospacedDigit()
                .padding(.trailing, 10)
        }
        .padding(.leading, 4)
        .padding(.vertical, 4)
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        let s = Int(d)
        let t = Int((d - Double(s)) * 10)
        return "\(s).\(t)"
    }
}

// MARK: - Breathing Ring

struct BreathingRing: View {
    let level: CGFloat
    let teal: Color
    @State private var breathe = false

    private var ringScale: CGFloat {
        1.0 + level * 0.4 + (breathe ? 0.05 : -0.05)
    }

    var body: some View {
        ZStack {
            // Outer breathing ring
            Circle()
                .stroke(teal.opacity(0.2 + level * 0.3), lineWidth: 1.5)
                .frame(width: 18, height: 18)
                .scaleEffect(ringScale)

            // Core dot
            Circle()
                .fill(teal)
                .frame(width: 6, height: 6)
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: breathe)
        .animation(.spring(duration: 0.15, bounce: 0.0), value: level)
        .onAppear { breathe = true }
    }
}

// MARK: - Transcribing Spinner

struct TranscribingSpinner: View {
    let teal: Color
    @State private var rotating = false

    var body: some View {
        ZStack {
            // 270-degree arc
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(teal.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(rotating ? 360 : 0))
        }
        .frame(width: 24, height: 24)
        .padding(4)
        .animation(
            .linear(duration: 0.8).repeatForever(autoreverses: false),
            value: rotating
        )
        .onAppear { rotating = true }
    }
}

// MARK: - Done Flash Dot

struct DoneFlashDot: View {
    @State private var flash = false

    private let green = Color(red: 0.2, green: 0.85, blue: 0.4)

    var body: some View {
        Circle()
            .fill(green)
            .frame(width: 6, height: 6)
            .opacity(flash ? 0.9 : 0.3)
            .padding(8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.15)) {
                    flash = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        flash = false
                    }
                }
            }
    }
}
