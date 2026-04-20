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

/// Short label for the active polish style
private func styleBadgeLabel(_ style: String, zh: Bool) -> String {
    switch style {
    case "auto": return zh ? "自动" : "Auto"
    case "spoken": return zh ? "口语" : "Spoken"
    case "concise": return zh ? "精简" : "Concise"
    case "structured": return zh ? "结构" : "Struct"
    case "custom": return zh ? "自定" : "Custom"
    default: return zh ? "自然" : "Natural"
    }
}

/// Cycle to next polish style (skip "custom" if no custom prompt is set)
private func nextPolishStyle(_ current: String, hasCustomPrompt: Bool) -> String {
    var order = ["spoken", "natural", "concise", "structured"]
    if hasCustomPrompt { order.append("custom") }
    guard let idx = order.firstIndex(of: current) else { return "spoken" }
    return order[(idx + 1) % order.count]
}

/// Style badge button (always visible, tap to cycle)
struct StyleBadgeButton: View {
    let style: String
    let zh: Bool
    var darkContent: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(styleBadgeLabel(style, zh: zh))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(darkContent ? .black.opacity(0.5) : .white.opacity(0.7))
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(
                    Capsule().fill(darkContent ? .black.opacity(0.08) : .white.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}

struct MinimalFlowBar: View {
    @Environment(AppState.self) var appState
    @State private var showDone = false
    @State private var showFailed = false
    @State private var stopPulse = false

    private var isToggleMode: Bool { appState.dictationMode == "toggle" }

    private var state: BarState {
        if showFailed { return .failed }
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
                if isToggleMode {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white)
                        .frame(width: 10, height: 10)
                        .opacity(stopPulse ? 1.0 : 0.4)
                }
                if appState.llmCleanupEnabled && appState.effectivePolishStyle != "auto" {
                    StyleBadgeButton(style: appState.effectivePolishStyle, zh: appState.uiLanguage == "zh") {
                        let next = nextPolishStyle(appState.effectivePolishStyle, hasCustomPrompt: !appState.customPolishPrompt.isEmpty)
                        if appState.activeStyleOverride != nil { appState.activeStyleOverride = next } else { appState.polishStyle = next }
                    }
                }
                AudioBars(level: appState.audioLevel, barWidth: 3, barMaxH: 16)
                Text(fmtTime(appState.recordingDuration))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                CancelButton(color: .white) { appState.cancelRecording() }
            }
            .opacity(state == .recording ? 1 : 0)

            // Transcribing
            HStack(spacing: 12) {
                if appState.llmCleanupEnabled && appState.effectivePolishStyle != "auto" {
                    StyleBadgeButton(style: appState.effectivePolishStyle, zh: appState.uiLanguage == "zh") {
                        let next = nextPolishStyle(appState.effectivePolishStyle, hasCustomPrompt: !appState.customPolishPrompt.isEmpty)
                        if appState.activeStyleOverride != nil { appState.activeStyleOverride = next } else { appState.polishStyle = next }
                    }
                }
                ShimmerBar(color: .white)
                    .frame(width: 80)
                CancelButton(color: .white) { appState.cancelRecording() }
            }
            .opacity(state == .transcribing ? 1 : 0)

            // Done
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .opacity(state == .done ? 1 : 0)

            // Failed
            HStack(spacing: 6) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Text(appState.uiLanguage == "zh" ? "复制失败" : "Paste failed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
            }
            .opacity(state == .failed ? 1 : 0)
        }
        .frame(height: 20)
        .padding(.leading, 18)
        .padding(.trailing, 12)
        .padding(.vertical, 9)
        .background(Capsule().fill(state == .failed ? Color(red: 0.65, green: 0.12, blue: 0.12) : .black))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                stopPulse = true
            }
        }
        .onChange(of: appState.recordingState) { old, new in
            if old == .transcribing && new == .idle {
                if appState.pasteFailed {
                    showFailed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showFailed = false
                    }
                } else {
                    showDone = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showDone = false
                    }
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
    @State private var showFailed = false

    private var state: BarState {
        if showFailed { return .failed }
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

            HStack(spacing: 6) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Text(appState.uiLanguage == "zh" ? "复制失败" : "Paste failed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
            }
            .opacity(state == .failed ? 1 : 0)
        }
        .frame(height: 20)
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(
            ZStack {
                Capsule().fill(state == .failed ? Color(red: 0.65, green: 0.12, blue: 0.12) : .black.opacity(0.85))
                if state != .failed {
                    Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1)
                }
            }
        )
        .onChange(of: appState.recordingState) { old, new in
            if old == .transcribing && new == .idle {
                if appState.pasteFailed {
                    showFailed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showFailed = false }
                } else {
                    showDone = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { showDone = false }
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
    @State private var showFailed = false
    @State private var stopPulse = false

    private var isToggleMode: Bool { appState.dictationMode == "toggle" }

    private var state: BarState {
        if showFailed { return .failed }
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
                        .fill(.black)
                        .frame(width: 10, height: 10)
                        .opacity(stopPulse ? 1.0 : 0.4)
                }
                if appState.llmCleanupEnabled && appState.effectivePolishStyle != "auto" {
                    StyleBadgeButton(style: appState.effectivePolishStyle, zh: appState.uiLanguage == "zh", darkContent: true) {
                        let next = nextPolishStyle(appState.effectivePolishStyle, hasCustomPrompt: !appState.customPolishPrompt.isEmpty)
                        if appState.activeStyleOverride != nil { appState.activeStyleOverride = next } else { appState.polishStyle = next }
                    }
                }
                AudioBars(level: appState.audioLevel, color: .black, barWidth: 3, barMaxH: 16)
                Text(fmtTime(appState.recordingDuration))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black)
                    .monospacedDigit()
                CancelButton(color: .black) { appState.cancelRecording() }
            }
            .opacity(state == .recording ? 1 : 0)

            HStack(spacing: 12) {
                if appState.llmCleanupEnabled && appState.effectivePolishStyle != "auto" {
                    StyleBadgeButton(style: appState.effectivePolishStyle, zh: appState.uiLanguage == "zh", darkContent: true) {
                        let next = nextPolishStyle(appState.effectivePolishStyle, hasCustomPrompt: !appState.customPolishPrompt.isEmpty)
                        if appState.activeStyleOverride != nil { appState.activeStyleOverride = next } else { appState.polishStyle = next }
                    }
                }
                ShimmerBar(color: .black)
                    .frame(width: 80)
                CancelButton(color: .black) { appState.cancelRecording() }
            }
            .opacity(state == .transcribing ? 1 : 0)

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.black)
                .opacity(state == .done ? 1 : 0)

            HStack(spacing: 6) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Text(appState.uiLanguage == "zh" ? "复制失败" : "Paste failed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
            }
            .opacity(state == .failed ? 1 : 0)
        }
        .frame(height: 20)
        .padding(.leading, 18)
        .padding(.trailing, 12)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(state == .failed ? Color(red: 0.65, green: 0.12, blue: 0.12) : .white)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 3)
        )
        .onChange(of: appState.recordingState) { old, new in
            if old == .transcribing && new == .idle {
                if appState.pasteFailed {
                    showFailed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showFailed = false }
                } else {
                    showDone = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { showDone = false }
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
    case hidden, recording, transcribing, done, failed
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
    @State private var phase: CGFloat = -0.6

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color.opacity(0.15))
            .frame(height: 4)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0), color.opacity(0.55), color.opacity(0)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.45)
                        .offset(x: phase * geo.size.width)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

// MARK: - Cancel Button

struct CancelButton: View {
    var color: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color.opacity(0.5))
                .frame(width: 16, height: 16)
                .background(Circle().fill(color.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

private func fmtTime(_ d: TimeInterval) -> String {
    "\(Int(d)).\(Int((d - Double(Int(d))) * 10))"
}
