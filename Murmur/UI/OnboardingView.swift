import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) var appState
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var step: Int = 0
    @State private var selectedModel: String = ""
    @State private var appeared = false
    @State private var permissionTimer: Timer?
    @State private var permissionsJustCompleted = false

    private var zh: Bool { appState.uiLanguage == "zh" }
    private let totalSteps = 4
    private var allPermissionsGranted: Bool { appState.microphoneGranted && appState.accessibilityGranted }

    private var stepAnimation: Animation {
        reduceMotion ? .default : .easeInOut(duration: 0.3)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                welcomeStep.opacity(step == 0 ? 1 : 0)
                permissionsStep.opacity(step == 1 ? 1 : 0)
                modelStep.opacity(step == 2 ? 1 : 0)
                readyStep.opacity(step == 3 ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(stepAnimation, value: step)

            bottomBar
        }
        .frame(minWidth: 580, minHeight: 520)
        .onAppear {
            selectedModel = recommendedModel
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) { appeared = true }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Step 0: Welcome
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {
                // Hero
                VStack(spacing: 20) {
                    MurmurLogo(color: .primary)
                        .frame(width: 64, height: 64)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    VStack(spacing: 8) {
                        Text(zh ? "用声音，代替打字" : "Speak Instead of Typing")
                            .font(.system(size: 28, weight: .semibold))
                            .opacity(appeared ? 1 : 0)

                        Text(zh ? "Murmur 在你的 Mac 上本地运行，安静、快速、私密" : "Murmur runs locally on your Mac — quiet, fast, and private")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                    }
                }

                // Features
                HStack(spacing: 16) {
                    featureCard(
                        icon: "lock.shield",
                        title: zh ? "完全离线" : "Fully Offline",
                        desc: zh ? "语音不会离开\n你的电脑" : "Your voice stays\non this Mac"
                    )
                    featureCard(
                        icon: "bolt",
                        title: zh ? "一键转写" : "One-Key Input",
                        desc: zh ? "按住 ⌥ 说话\n松开即粘贴" : "Hold ⌥ to speak\nrelease to paste"
                    )
                    featureCard(
                        icon: "sparkle",
                        title: zh ? "智能润色" : "AI Polish",
                        desc: zh ? "自动去除口语词\n补全标点" : "Auto-remove fillers\nfix punctuation"
                    )
                }
                .frame(maxWidth: 480)
                .opacity(appeared ? 1 : 0)

                // Language
                OnboardingLanguagePicker(zh: zh)
                    .opacity(appeared ? 1 : 0)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private func featureCard(icon: String, title: String, desc: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.secondary)
                .frame(height: 24)

            Text(title)
                .font(.system(size: 13, weight: .semibold))

            Text(desc)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                )
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Step 1: Permissions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var permissionsStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                // Header — changes when all granted
                VStack(spacing: 10) {
                    if allPermissionsGranted {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 32, weight: .thin))
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text(allPermissionsGranted
                         ? (zh ? "权限已就绪" : "Permissions Ready")
                         : (zh ? "需要你的许可" : "We Need Your Permission"))
                        .font(.system(size: 28, weight: .semibold))
                    Text(allPermissionsGranted
                         ? (zh ? "太好了，可以继续下一步了" : "Great, let's move on")
                         : (zh ? "两步授权，之后就能开始使用了" : "Two quick grants, then you're good to go"))
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .animation(.easeInOut(duration: 0.3), value: allPermissionsGranted)

                // Permission cards
                VStack(spacing: 12) {
                    permissionCard(
                        icon: "mic.fill",
                        title: zh ? "麦克风" : "Microphone",
                        desc: zh ? "Murmur 需要听到你的声音才能转写" : "Murmur needs to hear you to transcribe",
                        granted: appState.microphoneGranted,
                        action: {
                            openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
                        }
                    )
                    permissionCard(
                        icon: "accessibility",
                        title: zh ? "辅助功能" : "Accessibility",
                        desc: zh ? "用来把文字自动粘贴到你正在使用的应用" : "Lets Murmur paste text into the app you're using",
                        granted: appState.accessibilityGranted,
                        action: {
                            openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                        }
                    )
                }
                .frame(maxWidth: 420)

                if !allPermissionsGranted {
                    Text(zh ? "点击授权后会跳到系统设置，完成后回到这里就行" : "You'll be taken to System Settings, come back here when done")
                        .font(.system(size: 12))
                        .foregroundStyle(.quaternary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .onAppear { startPermissionPolling() }
        .onDisappear { stopPermissionPolling() }
    }

    private func startPermissionPolling() {
        appState.refreshPermissions()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                appState.refreshPermissions()
            }
        }
    }

    private func stopPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    private func permissionCard(icon: String, title: String, desc: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(granted ? Color.green.opacity(0.1) : Color.primary.opacity(0.04))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(granted ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(desc).font(.system(size: 11)).foregroundStyle(.tertiary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 18))
            } else {
                Button(action: action) {
                    Text(zh ? "前往授权" : "Grant")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(granted ? Color.green.opacity(0.03) : Color.primary.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(granted ? Color.green.opacity(0.12) : Color.primary.opacity(0.05), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.25), value: granted)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Step 2: Model
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var modelStep: some View {
        VStack(spacing: 0) {
            Spacer()

            if appState.modelLoaded {
                // ── Model ready: big success card ──
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(.green)

                    VStack(spacing: 8) {
                        Text(zh ? "语音引擎已就绪" : "Voice Engine Ready")
                            .font(.system(size: 28, weight: .semibold))
                        Text(zh ? "\(appState.whisperModel.replacingOccurrences(of: "_", with: " ")) 已下载并编译完成"
                             : "\(appState.whisperModel.replacingOccurrences(of: "_", with: " ")) downloaded and compiled")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    Text(zh ? "你可以随时在设置中更换模型" : "You can switch models anytime in Settings")
                        .font(.system(size: 12))
                        .foregroundStyle(.quaternary)
                }
            } else {
                // ── Model selection ──
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 10) {
                        Text(zh ? "选一个语音引擎" : "Pick a Voice Engine")
                            .font(.system(size: 28, weight: .semibold))
                        Text(zh ? "模型越大识别越准，已根据你的 Mac 推荐了最佳选项" : "Bigger models hear better — we've picked the best fit for your Mac")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 440)
                    }

                    // Model list
                    VStack(spacing: 0) {
                        ForEach(Array(modelOptions.enumerated()), id: \.element.name) { index, model in
                            if index > 0 {
                                Divider().padding(.leading, 48)
                            }
                            modelRow(model: model)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary.opacity(0.02))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                            )
                    )
                    .frame(maxWidth: 500)

                    // Progress / download button
                    modelActionArea
                        .frame(maxWidth: 500)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .animation(.easeInOut(duration: 0.3), value: appState.modelLoaded)
    }

    private var systemRAM: Int {
        Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024))
    }

    private func modelRow(model: ModelOption) -> some View {
        let isSelected = selectedModel == model.name
        let isRecommended = model.name == recommendedModel
        let isDownloaded = appState.downloadedWhisperModels.contains(model.name)
        let needsMoreRAM = model.minRAM > systemRAM

        return Button(action: {
            guard !appState.modelLoading else { return }
            withAnimation(.easeInOut(duration: 0.15)) { selectedModel = model.name }
        }) {
            HStack(spacing: 12) {
                // Radio
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if isSelected {
                        Circle().fill(Color.accentColor).frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(model.label)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        if isRecommended {
                            Text(zh ? "推荐" : "Best fit")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor.opacity(0.1)))
                        }
                        if needsMoreRAM {
                            Text(zh ? "需 \(model.minRAM)GB 内存" : "\(model.minRAM)GB RAM")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange.opacity(0.08)))
                        }
                        if isDownloaded {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10)).foregroundStyle(.green.opacity(0.7))
                        }
                    }
                    Text(model.desc(zh: zh))
                        .font(.system(size: 11)).foregroundStyle(.tertiary)
                }

                Spacer()

                Text(model.size)
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.04) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(appState.modelLoading)
    }

    @ViewBuilder
    private var modelActionArea: some View {
        if appState.modelLoading {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: appState.modelLoadPhase == "compile" ? "gearshape.2" : "arrow.down.circle")
                        .font(.system(size: 14)).foregroundStyle(.blue).frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.modelLoadPhase == "compile"
                             ? (zh ? "正在编译模型…" : "Compiling model…")
                             : (zh ? "正在下载…" : "Downloading…"))
                            .font(.system(size: 13, weight: .medium))
                        Text(appState.modelLoadPhase == "compile"
                             ? (zh ? "转换为 Apple 芯片格式，大约需要 1-2 分钟" : "Converting for Apple Silicon, takes about 1-2 min")
                             : (zh ? "正在从 Hugging Face 获取模型" : "Fetching model from Hugging Face"))
                            .font(.system(size: 11)).foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Text("\(Int(appState.modelLoadProgress * 100))%")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)

                    Button { appState.cancelModelLoad() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13)).foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain).help(zh ? "取消" : "Cancel")
                }

                ProgressView(value: appState.modelLoadProgress).tint(.blue)

                // Phase breadcrumb
                HStack(spacing: 12) {
                    phaseLabel(zh ? "下载" : "Download",
                              active: appState.modelLoadPhase == "download",
                              done: appState.modelLoadPhase == "compile")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 7)).foregroundStyle(.quaternary)
                    phaseLabel(zh ? "编译" : "Compile",
                              active: appState.modelLoadPhase == "compile",
                              done: false)
                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.blue.opacity(0.08), lineWidth: 1))
            )
        } else if appState.modelLoaded {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 16))
                Text(zh ? "模型就绪，可以继续了" : "Model ready — let's go")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        } else if let failed = appState.failedModelName {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.system(size: 14))
                Text(zh ? "\(failed) 没有下完整，再试一次？" : "\(failed) didn't finish — try again?")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                Spacer()
                Button(zh ? "重试" : "Retry") { appState.retryModelDownload() }
                    .buttonStyle(.borderedProminent).controlSize(.small)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.orange.opacity(0.1), lineWidth: 1))
            )
        } else {
            Button(action: {
                appState.whisperModel = selectedModel
                Task { await appState.loadModel() }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle")
                    Text(zh ? "下载并安装" : "Download & Install")
                }
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func phaseLabel(_ text: String, active: Bool, done: Bool) -> some View {
        HStack(spacing: 4) {
            if done {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 9)).foregroundStyle(.green)
            } else {
                Circle().fill(active ? Color.blue : Color.primary.opacity(0.1)).frame(width: 6, height: 6)
            }
            Text(text)
                .font(.system(size: 10, weight: active ? .medium : .regular))
                .foregroundStyle(active ? .primary : .quaternary)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Step 3: Ready
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var readyStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                VStack(spacing: 20) {
                    MurmurLogo(color: .primary)
                        .frame(width: 56, height: 56)

                    VStack(spacing: 8) {
                        Text(zh ? "准备好了" : "You're All Set")
                            .font(.system(size: 28, weight: .semibold))
                        Text(zh ? "Murmur 在菜单栏静静等你，随时可以说话" : "Murmur lives in your menu bar, ready whenever you are")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Quick reference
                VStack(alignment: .leading, spacing: 0) {
                    Text(zh ? "记住这三个操作" : "Three things to remember")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                        .tracking(0.3)
                        .padding(.bottom, 12)

                    VStack(spacing: 0) {
                        shortcutRow(
                            key: "Right ⌥",
                            title: zh ? "按住说话，松开完成" : "Hold to speak, release to finish",
                            desc: zh ? "转写结果自动粘贴到光标处" : "Transcription auto-pastes at your cursor",
                            isFirst: true
                        )
                        shortcutRow(
                            key: "Esc",
                            title: zh ? "随时取消" : "Cancel anytime",
                            desc: zh ? "说错了？按 Esc 丢掉这次录音" : "Changed your mind? Press Esc to discard",
                            isFirst: false
                        )
                        shortcutRow(
                            key: "|||",
                            title: zh ? "点击菜单栏图标" : "Click the menu bar icon",
                            desc: zh ? "查看状态、历史记录、打开设置" : "Check status, history, and open settings",
                            isFirst: false,
                            useLogo: true
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.primary.opacity(0.02))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: 420)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private func shortcutRow(key: String, title: String, desc: String, isFirst: Bool, useLogo: Bool = false) -> some View {
        VStack(spacing: 0) {
            if !isFirst {
                Divider().padding(.leading, 80)
            }
            HStack(spacing: 16) {
                Group {
                    if useLogo {
                        MurmurLogo(color: .primary)
                            .frame(width: 16, height: 16)
                    } else {
                        Text(key)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                }
                .frame(width: 60)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.05))
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .medium))
                    Text(desc).font(.system(size: 11)).foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Bottom Bar
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var bottomBar: some View {
        HStack {
            // Step dots
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? Color.primary.opacity(0.6) : Color.primary.opacity(0.12))
                        .frame(width: i == step ? 18 : 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: step)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if step > 0 {
                    Button(zh ? "上一步" : "Back") {
                        withAnimation(stepAnimation) { step -= 1 }
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                }

                if step == totalSteps - 1 {
                    Button(zh ? "开始使用" : "Get Started") {
                        appState.dismissOnboarding()
                    }
                    .buttonStyle(.borderedProminent).controlSize(.regular)
                } else {
                    Button(zh ? "继续" : "Continue") {
                        withAnimation(stepAnimation) { step += 1 }
                    }
                    .buttonStyle(.borderedProminent).controlSize(.regular)
                    .disabled(step == 2 && !appState.modelLoaded)
                }
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 18)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Model Data
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private struct ModelOption {
        let name, label, size: String
        let minRAM: Int
        let descZh, descEn: String
        func desc(zh: Bool) -> String { zh ? descZh : descEn }
    }

    private var modelOptions: [ModelOption] {[
        .init(name: "tiny", label: "Tiny", size: "39 MB", minRAM: 4,
              descZh: "最快，适合短句", descEn: "Fastest, good for short phrases"),
        .init(name: "base", label: "Base", size: "140 MB", minRAM: 4,
              descZh: "速度和准确度均衡", descEn: "Balanced speed and accuracy"),
        .init(name: "small", label: "Small", size: "460 MB", minRAM: 8,
              descZh: "多语言日常首选", descEn: "Great multilingual daily driver"),
        .init(name: "large-v3_turbo", label: "Large v3 Turbo", size: "1.6 GB", minRAM: 16,
              descZh: "高准确度，速度优化", descEn: "High accuracy, speed optimized"),
        .init(name: "large-v3", label: "Large v3", size: "3 GB", minRAM: 24,
              descZh: "最高准确度", descEn: "Best accuracy available"),
    ]}

    private var recommendedModel: String {
        let ram = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024))
        if ram >= 24 { return "large-v3" }
        if ram >= 16 { return "large-v3_turbo" }
        if ram >= 8 { return "small" }
        return "base"
    }

    // MARK: - Helpers

    private func openSystemSettings(_ url: String) {
        if let url = URL(string: url) { NSWorkspace.shared.open(url) }
    }
}

// MARK: - Language Picker

private struct OnboardingLanguagePicker: View {
    @Environment(AppState.self) var appState
    let zh: Bool

    var body: some View {
        @Bindable var appState = appState
        HStack(spacing: 10) {
            Text(zh ? "界面语言" : "Language")
                .font(.system(size: 12)).foregroundStyle(.tertiary)
            Picker("", selection: $appState.uiLanguage) {
                Text("中文").tag("zh")
                Text("English").tag("en")
            }
            .labelsHidden().pickerStyle(.segmented).frame(width: 130)
        }
    }
}
