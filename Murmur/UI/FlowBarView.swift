import SwiftUI

// MARK: - FlowBar Theme Router

struct FlowBarView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        Group {
            switch appState.flowBarTheme {
            case "outline":
                OutlineFlowBar()
            case "invert":
                InvertFlowBar()
            default:
                MinimalFlowBar()
            }
        }
        .environment(appState)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Theme A: 极简 (Minimal)
// Solid black pill. White content. No border.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct MinimalFlowBar: View {
    @Environment(AppState.self) var appState
    @State private var showDone = false
    @State private var stopPulse = false

    private var isToggleMode: Bool { appState.dictationMode == "toggle" }

    private var state: BarState {
        if showDone { return .done }
        switch appState.recordingState {
        case .idle: return .hidden
        case .recording: return .recording
        case .transcribing: return .transcribing
        }
    }

    var body: some View {
        ZStack {
            // Recording
            HStack(spacing: 10) {
                // Toggle mode: show stop indicator
                if isToggleMode {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.red)
                        .frame(width: 10, height: 10)
                        .opacity(stopPulse ? 1.0 : 0.5)
                }
                AudioBars(level: appState.audioLevel, barWidth: 3, barMaxH: 16)
                Text(fmtTime(appState.recordingDuration))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .opacity(state == .recording ? 1 : 0)

            // Transcribing
            ShimmerBar(color: .white)
                .frame(width: 48)
                .opacity(state == .transcribing ? 1 : 0)

            // Done
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .opacity(state == .done ? 1 : 0)
        }
        .frame(height: 20)
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(Capsule().fill(.black))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                stopPulse = true
            }
        }
        .onChange(of: appState.recordingState) { old, new in
            if old == .transcribing && new == .idle {
                showDone = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showDone = false
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: state)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Theme B: 线框 (Outline)
// No fill. White border. Content floats on screen edge.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct OutlineFlowBar: View {
    @Environment(AppState.self) var appState
    @State private var showDone = false

    private var state: BarState {
        if showDone { return .done }
        switch appState.recordingState {
        case .idle: return .hidden
        case .recording: return .recording
        case .transcribing: return .transcribing
        }
    }

    var body: some View {
        ZStack {
            HStack(spacing: 10) {
                AudioBars(level: appState.audioLevel, barWidth: 3, barMaxH: 16)
                Text(fmtTime(appState.recordingDuration))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .opacity(state == .recording ? 1 : 0)

            HStack(spacing: 6) {
                ThreeDots(color: .white)
                Text("处理中")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .opacity(state == .transcribing ? 1 : 0)

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .opacity(state == .done ? 1 : 0)
        }
        .frame(height: 20)
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(
            ZStack {
                Capsule().fill(.black.opacity(0.85))
                Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1)
            }
        )
        .onChange(of: appState.recordingState) { old, new in
            if old == .transcribing && new == .idle {
                showDone = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showDone = false
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: state)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Theme C: 反转 (Invert)
// White pill. Black content. High visibility on any wallpaper.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct InvertFlowBar: View {
    @Environment(AppState.self) var appState
    @State private var showDone = false
    @State private var stopPulse = false

    private var isToggleMode: Bool { appState.dictationMode == "toggle" }

    private var state: BarState {
        if showDone { return .done }
        switch appState.recordingState {
        case .idle: return .hidden
        case .recording: return .recording
        case .transcribing: return .transcribing
        }
    }

    var body: some View {
        ZStack {
            HStack(spacing: 10) {
                if isToggleMode {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.red)
                        .frame(width: 10, height: 10)
                        .opacity(stopPulse ? 1.0 : 0.5)
                }
                AudioBars(level: appState.audioLevel, color: .black, barWidth: 3, barMaxH: 16)
                Text(fmtTime(appState.recordingDuration))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black)
                    .monospacedDigit()
            }
            .opacity(state == .recording ? 1 : 0)

            ShimmerBar(color: .black)
                .frame(width: 48)
                .opacity(state == .transcribing ? 1 : 0)

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.black)
                .opacity(state == .done ? 1 : 0)
        }
        .frame(height: 20)
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(.white)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 3)
        )
        .onChange(of: appState.recordingState) { old, new in
            if old == .transcribing && new == .idle {
                showDone = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showDone = false
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: state)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                stopPulse = true
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - State Enum
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private enum BarState: Equatable {
    case hidden, recording, transcribing, done
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Shared Components
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct AudioBars: View {
    let level: Float
    var color: Color = .white
    var barWidth: CGFloat = 3
    var barMaxH: CGFloat = 16
    private let barCount = 5
    @State private var heights: [CGFloat] = Array(repeating: 2, count: 5)

    var body: some View {
        HStack(spacing: barWidth * 0.8) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(color)
                    .frame(width: barWidth, height: heights[i])
            }
        }
        .frame(height: barMaxH)
        .onChange(of: level) { _, v in update(v) }
        .onAppear { update(level) }
    }

    private func update(_ input: Float) {
        let n = CGFloat(min(max(input * 10, 0), 1.0))
        let s: [CGFloat] = [0.4, 0.75, 1.0, 0.65, 0.3]
        for i in 0..<barCount {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 12).delay(Double(i) * 0.02)) {
                heights[i] = max(2, n * barMaxH * s[i])
            }
        }
    }
}

struct ThreeDots: View {
    var color: Color = .white
    @State private var active = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color.opacity(i == active ? 1.0 : 0.25))
                    .frame(width: 4, height: 4)
                    .animation(.easeInOut(duration: 0.2), value: active)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                active = (active + 1) % 3
            }
        }
    }
}

struct ShimmerBar: View {
    var color: Color = .white
    @State private var phase: CGFloat = -0.5

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color.opacity(0.15))
            .frame(height: 3)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0), color.opacity(0.6), color.opacity(0)],
                                startPoint: .leading, endPoint: .trailing
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

// MARK: - Helpers

private func fmtTime(_ d: TimeInterval) -> String {
    "\(Int(d)).\(Int((d - Double(Int(d))) * 10))"
}
