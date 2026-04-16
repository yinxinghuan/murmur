import SwiftUI

struct FlowBarView: View {
    @Environment(AppState.self) var appState
    @State private var showDoneCheck: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            switch appState.recordingState {
            case .idle:
                if showDoneCheck {
                    doneContent
                } else {
                    idleContent
                }
            case .recording:
                recordingContent
            case .transcribing:
                transcribingContent
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 7)
        .background(background)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
        .shadow(color: glowColor.opacity(0.12), radius: 20, y: 0)
        .opacity(appState.recordingState == .idle && !showDoneCheck ? 0.4 : 1.0)
        .scaleEffect(appState.recordingState == .recording ? 1.02 : 1.0)
        .animation(.spring(duration: 0.3, bounce: 0.12), value: appState.recordingState)
        .animation(.easeInOut(duration: 0.25), value: showDoneCheck)
        .onChange(of: appState.recordingState) { oldState, newState in
            if oldState == .transcribing && newState == .idle {
                withAnimation(.easeOut(duration: 0.2)) {
                    showDoneCheck = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showDoneCheck = false
                    }
                }
            }
        }
    }

    // MARK: - Layout

    private var horizontalPadding: CGFloat {
        switch appState.recordingState {
        case .idle: return showDoneCheck ? 12 : 10
        case .recording: return 14
        case .transcribing: return 12
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Capsule().fill(.ultraThinMaterial)
            Capsule().fill(Color.black.opacity(backgroundOpacity))
            Capsule().strokeBorder(borderColor, lineWidth: 0.5)
        }
    }

    private var backgroundOpacity: Double {
        switch appState.recordingState {
        case .idle: return 0.45
        case .recording: return 0.55
        case .transcribing: return 0.5
        }
    }

    private var borderColor: Color {
        switch appState.recordingState {
        case .idle: return .white.opacity(0.06)
        case .recording: return teal.opacity(0.25)
        case .transcribing: return .white.opacity(0.08)
        }
    }

    private var glowColor: Color {
        appState.recordingState == .recording ? teal : .clear
    }

    private var teal: Color {
        Color(red: 0.08, green: 0.72, blue: 0.65)
    }

    // MARK: - Idle

    private var idleContent: some View {
        HStack(spacing: 5) {
            Image(systemName: "mic.fill")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(appState.modelLoaded ? .white.opacity(0.3) : .orange.opacity(0.7))

            if appState.modelLoading {
                ProgressView()
                    .controlSize(.mini)
                    .tint(.white.opacity(0.35))
                if appState.modelIsDownloading {
                    Text("\(Int(appState.modelLoadProgress * 100))%")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            } else if !appState.modelLoaded {
                Circle()
                    .fill(.orange.opacity(0.5))
                    .frame(width: 4, height: 4)
            }
        }
    }

    // MARK: - Done

    private var doneContent: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.green.opacity(0.8))
    }

    // MARK: - Recording

    private var recordingContent: some View {
        HStack(spacing: 10) {
            BreathingDot(color: teal)
            LiveWaveform(level: appState.audioLevel, color: teal)
            Text(formatDuration(appState.recordingDuration))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .monospacedDigit()
        }
    }

    // MARK: - Transcribing

    private var transcribingContent: some View {
        ShimmerBar(color: teal)
            .frame(width: 48)
    }

    // MARK: - Helpers

    private func formatDuration(_ d: TimeInterval) -> String {
        "\(Int(d)).\(Int((d - Double(Int(d))) * 10))"
    }
}

// MARK: - Breathing Dot

struct BreathingDot: View {
    let color: Color
    @State private var phase = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 14, height: 14)
                .scaleEffect(phase ? 1.3 : 0.9)
                .opacity(phase ? 0.0 : 0.4)
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
        }
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: phase)
        .onAppear { phase = true }
    }
}

// MARK: - Live Waveform

struct LiveWaveform: View {
    let level: Float
    let color: Color
    private let barCount = 5
    @State private var heights: [CGFloat] = Array(repeating: 2, count: 5)

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color.opacity(0.65))
                    .frame(width: 2, height: heights[i])
            }
        }
        .frame(height: 14)
        .onChange(of: level) { _, v in update(v) }
        .onAppear { update(level) }
    }

    private func update(_ input: Float) {
        let n = CGFloat(min(max(input * 10, 0), 1.0))
        let s: [CGFloat] = [0.4, 0.75, 1.0, 0.65, 0.3]
        for i in 0..<barCount {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 12).delay(Double(i) * 0.02)) {
                heights[i] = max(2, n * 12 * s[i])
            }
        }
    }
}

// MARK: - Shimmer Bar

struct ShimmerBar: View {
    let color: Color
    @State private var phase: CGFloat = -0.5

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color.opacity(0.12))
            .frame(height: 3)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0), color.opacity(0.45), color.opacity(0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.35)
                        .offset(x: phase * geo.size.width)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}
