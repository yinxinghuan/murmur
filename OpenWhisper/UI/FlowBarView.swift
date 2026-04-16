import SwiftUI

// MARK: - Main FlowBar (Theme Router)

struct FlowBarView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        Group {
            switch appState.flowBarTheme {
            case "spatialGlass":
                SpatialGlassFlowBar()
            case "aurora":
                AuroraFlowBar()
            default:
                VoiceFirstFlowBar()
            }
        }
        .environment(appState)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Theme A: Voice-First
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct VoiceFirstFlowBar: View {
    @Environment(AppState.self) var appState
    @State private var showDoneFlash = false
    private let teal = Color(red: 0.08, green: 0.72, blue: 0.65)

    var body: some View {
        ZStack {
            switch appState.recordingState {
            case .idle:
                if showDoneFlash {
                    DoneFlashDot()
                } else {
                    EmptyView()
                }
            case .recording:
                VFRecordingPill(audioLevel: appState.audioLevel, duration: appState.recordingDuration, teal: teal)
            case .transcribing:
                VFSpinner(teal: teal)
            }
        }
        .background(
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(Color.black.opacity(0.5))
            }
        )
        .clipShape(Capsule())
        .animation(.spring(duration: 0.3, bounce: 0.1), value: appState.recordingState)
        .animation(.spring(duration: 0.3, bounce: 0.1), value: showDoneFlash)
        .onChange(of: appState.recordingState) { old, new in
            if old == .transcribing && new == .idle {
                withAnimation { showDoneFlash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation { showDoneFlash = false }
                }
            }
        }
    }
}

private struct VFRecordingPill: View {
    let audioLevel: Float
    let duration: TimeInterval
    let teal: Color

    var body: some View {
        HStack(spacing: 0) {
            BreathingRing(level: CGFloat(min(max(audioLevel * 8, 0), 1.0)), teal: teal)
                .frame(width: 32, height: 32)
            Text(fmtDuration(duration))
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .monospacedDigit()
                .padding(.trailing, 10)
        }
        .padding(.leading, 4).padding(.vertical, 4)
    }
}

private struct VFSpinner: View {
    let teal: Color
    @State private var rotating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(teal.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .frame(width: 14, height: 14)
            .rotationEffect(.degrees(rotating ? 360 : 0))
            .frame(width: 24, height: 24)
            .padding(4)
            .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: rotating)
            .onAppear { rotating = true }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Theme B: Spatial Glass
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SpatialGlassFlowBar: View {
    @Environment(AppState.self) var appState
    @State private var showDoneCheck = false
    private let teal = Color(red: 0.08, green: 0.72, blue: 0.65)

    var body: some View {
        HStack(spacing: 0) {
            switch appState.recordingState {
            case .idle:
                if showDoneCheck { sgDoneContent } else { EmptyView() }
            case .recording: sgRecordingContent
            case .transcribing: sgTranscribingContent
            }
        }
        .padding(.horizontal, appState.recordingState == .recording ? 16 : 14)
        .padding(.vertical, 8)
        .background(sgBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
        .shadow(color: (appState.recordingState == .recording ? teal : .clear).opacity(0.15), radius: 24, y: 0)
        .scaleEffect(appState.recordingState == .recording ? 1.02 : 1.0)
        .animation(.spring(duration: 0.25, bounce: 0.12), value: appState.recordingState)
        .animation(.easeInOut(duration: 0.25), value: showDoneCheck)
        .onChange(of: appState.recordingState) { old, new in
            if old == .transcribing && new == .idle {
                withAnimation { showDoneCheck = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation { showDoneCheck = false }
                }
            }
        }
    }

    private var sgBackground: some View {
        ZStack {
            Capsule().fill(.ultraThickMaterial)
            Capsule().fill(Color.black.opacity(0.3))
            Capsule().fill(
                RadialGradient(
                    colors: [.white.opacity(appState.recordingState == .recording ? 0.05 : 0.03), .clear],
                    center: .top, startRadius: 0, endRadius: 40
                )
            )
            Capsule().strokeBorder(
                appState.recordingState == .recording ? teal.opacity(0.2) : .white.opacity(0.1),
                lineWidth: 0.5
            )
        }
    }

    private var sgDoneContent: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.green.opacity(0.7))
    }

    private var sgRecordingContent: some View {
        HStack(spacing: 10) {
            SGPulsingDot(color: teal)
            AudioBars(level: appState.audioLevel, color: teal)
            Text(fmtDuration(appState.recordingDuration))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .monospacedDigit()
        }
    }

    private var sgTranscribingContent: some View {
        HStack(spacing: 6) {
            SequentialDots(color: teal)
            Text("处理中")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

private struct SGPulsingDot: View {
    let color: Color
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: 1.5)
                .frame(width: 16, height: 16)
                .scaleEffect(pulse ? 1.4 : 0.9)
                .opacity(pulse ? 0.0 : 0.5)
            Circle().fill(color.opacity(0.1))
                .frame(width: 14, height: 14)
                .scaleEffect(pulse ? 1.3 : 0.9)
                .opacity(pulse ? 0.0 : 0.3)
            Circle().fill(color).frame(width: 7, height: 7)
                .shadow(color: color.opacity(0.4), radius: 4)
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Theme C: Aurora
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct AuroraFlowBar: View {
    @Environment(AppState.self) var appState
    @State private var showDoneCheck = false
    @State private var auroraPhase: CGFloat = 0
    @State private var doneFlash = false

    var body: some View {
        HStack(spacing: 0) {
            switch appState.recordingState {
            case .idle:
                if showDoneCheck { auroraDoneContent } else { EmptyView() }
            case .recording: auroraRecordingContent
            case .transcribing: auroraTranscribingContent
            }
        }
        .padding(.horizontal, appState.recordingState == .recording ? 14 : 12)
        .padding(.vertical, 7)
        .background(auroraBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
        .shadow(color: auroraShadowColor.opacity(auroraShadowOpacity), radius: 20, y: 0)
        .scaleEffect(appState.recordingState == .recording ? 1.02 : 1.0)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: appState.recordingState)
        .animation(.easeInOut(duration: 0.25), value: showDoneCheck)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                auroraPhase = 1.0
            }
        }
        .onChange(of: appState.recordingState) { old, new in
            if old == .transcribing && new == .idle {
                doneFlash = true
                withAnimation { showDoneCheck = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { showDoneCheck = false; doneFlash = false }
                }
            }
        }
    }

    // Aurora background
    private var auroraBackground: some View {
        ZStack {
            Capsule().fill(Color.black.opacity(0.6))
            Capsule().fill(auroraGradient).opacity(auroraOpacity)
            Capsule().fill(.ultraThinMaterial).opacity(0.15)
            Capsule().strokeBorder(
                appState.recordingState == .recording ? Color(h: 0x14B8A6).opacity(0.25) : .white.opacity(0.06),
                lineWidth: 0.5
            )
        }
    }

    private var auroraGradient: LinearGradient {
        let colors: [Color] = doneFlash
            ? [Color(h: 0x22C55E), Color(h: 0x14B8A6)]
            : auroraColors
        let angle = auroraPhase * .pi * 2
        return LinearGradient(
            colors: colors,
            startPoint: UnitPoint(x: 0.5 + 0.5 * cos(angle), y: 0.5 + 0.3 * sin(angle)),
            endPoint: UnitPoint(x: 0.5 - 0.5 * cos(angle), y: 0.5 - 0.3 * sin(angle))
        )
    }

    private var auroraColors: [Color] {
        switch appState.recordingState {
        case .idle: return [Color(h: 0x14B8A6), Color(h: 0x8B5CF6)]
        case .recording: return [Color(h: 0x14B8A6), Color(h: 0x3B82F6), Color(h: 0x8B5CF6)]
        case .transcribing: return [Color(h: 0x14B8A6).opacity(0.7), Color(h: 0x8B5CF6).opacity(0.7)]
        }
    }

    private var auroraOpacity: Double {
        if doneFlash { return 0.7 }
        switch appState.recordingState {
        case .idle: return 0.15
        case .recording: return 0.6
        case .transcribing: return 0.3
        }
    }

    private var auroraShadowColor: Color {
        if doneFlash { return Color(h: 0x22C55E) }
        switch appState.recordingState {
        case .idle: return .clear
        case .recording:
            return sin(auroraPhase * .pi * 2) > 0 ? Color(h: 0x8B5CF6) : Color(h: 0x14B8A6)
        case .transcribing: return Color(h: 0x3B82F6)
        }
    }

    private var auroraShadowOpacity: Double {
        if doneFlash { return 0.4 }
        switch appState.recordingState {
        case .idle: return 0
        case .recording: return 0.25
        case .transcribing: return 0.1
        }
    }

    private var auroraDoneContent: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.green.opacity(0.8))
    }

    private var auroraRecordingContent: some View {
        HStack(spacing: 10) {
            AudioBars(level: appState.audioLevel, color: .white.opacity(0.8))
            Text(fmtDuration(appState.recordingDuration))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .monospacedDigit()
        }
    }

    private var auroraTranscribingContent: some View {
        HStack(spacing: 6) {
            ShimmerBar(color: .white)
                .frame(width: 32)
            Text("识别中")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Shared Components
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BreathingRing: View {
    let level: CGFloat
    let teal: Color
    @State private var breathe = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(teal.opacity(0.2 + level * 0.3), lineWidth: 1.5)
                .frame(width: 18, height: 18)
                .scaleEffect(1.0 + level * 0.4 + (breathe ? 0.05 : -0.05))
            Circle().fill(teal).frame(width: 6, height: 6)
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: breathe)
        .animation(.spring(duration: 0.15, bounce: 0.0), value: level)
        .onAppear { breathe = true }
    }
}

struct AudioBars: View {
    let level: Float
    let color: Color
    private let barCount = 5
    @State private var heights: [CGFloat] = Array(repeating: 2, count: 5)

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.25)
                    .fill(color)
                    .frame(width: 2.5, height: heights[i])
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

struct SequentialDots: View {
    let color: Color
    @State private var activeIndex = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i == activeIndex ? color : color.opacity(0.2))
                    .frame(width: 4, height: 4)
                    .shadow(color: i == activeIndex ? color.opacity(0.4) : .clear, radius: 3)
                    .animation(.easeInOut(duration: 0.2), value: activeIndex)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                activeIndex = (activeIndex + 1) % 3
            }
        }
    }
}

struct ShimmerBar: View {
    let color: Color
    @State private var phase: CGFloat = -0.5

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color.opacity(0.1))
            .frame(height: 3)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0), color.opacity(0.4), color.opacity(0)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.35)
                        .offset(x: phase * geo.size.width)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

struct DoneFlashDot: View {
    @State private var flash = false

    var body: some View {
        Circle()
            .fill(Color(red: 0.2, green: 0.85, blue: 0.4))
            .frame(width: 6, height: 6)
            .opacity(flash ? 0.9 : 0.3)
            .padding(8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.15)) { flash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.6)) { flash = false }
                }
            }
    }
}

// MARK: - Helpers

private func fmtDuration(_ d: TimeInterval) -> String {
    "\(Int(d)).\(Int((d - Double(Int(d))) * 10))"
}

private extension Color {
    init(h: UInt32) {
        self.init(
            red: Double((h >> 16) & 0xFF) / 255,
            green: Double((h >> 8) & 0xFF) / 255,
            blue: Double(h & 0xFF) / 255
        )
    }
}
