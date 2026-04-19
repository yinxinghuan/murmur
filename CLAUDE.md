# Murmur — macOS 本地语音转文字

Fork of [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app)，MIT 协议。
**核心定位：人与 AI 代理沟通的语音桥梁。**

GitHub: https://github.com/yinxinghuan/murmur
当前版本: v1.6.2

## Tech Stack

- Swift / SwiftUI, macOS 14+, Apple Silicon (ARM64)
- SPM (Swift Package Manager), WhisperKit 0.9+
- Ollama (本地 LLM 润色)
- Bundle ID: `com.yinxinghuan.murmur`

## Build

```bash
# Debug
swift build -c debug --arch arm64

# Release
swift build -c release --arch arm64
# 或
bash build.sh
```

**必须 `--arch arm64`**，否则默认 x86 + Rosetta 会导致 CoreML 崩溃。

打包 .app:
```bash
ARCH_DIR=".build/arm64-apple-macosx/release"
APP_DIR="build/Murmur.app/Contents"
mkdir -p "$APP_DIR/MacOS" "$APP_DIR/Resources" "$APP_DIR/Frameworks"
cp "$ARCH_DIR/Murmur" "$APP_DIR/MacOS/Murmur"
cp Murmur/Info.plist "$APP_DIR/Info.plist"
cp Murmur/Resources/AppIcon.icns "$APP_DIR/Resources/AppIcon.icns"
[ -d "$ARCH_DIR/Murmur_Murmur.bundle" ] && cp -R "$ARCH_DIR/Murmur_Murmur.bundle" "$APP_DIR/Resources/"
codesign --force --deep --sign - build/Murmur.app
cp -R build/Murmur.app /Applications/
```

## 项目结构

```
Murmur/
├── App/
│   ├── AppState.swift        — 全局状态、录音流程、设置持久化、语音指令、转写历史
│   └── MurmurApp.swift       — 入口、菜单栏图标
├── Core/
│   ├── AudioEngine.swift     — 麦克风采集 + 16kHz 重采样
│   ├── WhisperTranscriber.swift — 模型加载/校验/转写、幻觉过滤
│   ├── LLMCleanup.swift      — Ollama LLM 润色 + 术语保护
│   ├── TextInjector.swift    — 自动粘贴 (CGEvent Cmd+V)
│   └── ReminderManager.swift — 语音提醒
├── Hotkey/GlobalHotkey.swift  — 右 Option 键监听（按住/切换两种模式）
├── UI/
│   ├── FlowBarView.swift     — 2 主题 FlowBar（黑底/白底）
│   ├── FlowBarWindow.swift   — NSPanel 浮窗控制
│   ├── SettingsView.swift    — 设置面板（中英双语）
│   ├── MurmurLogo.swift      — 波形 Logo + 菜单栏图标
│   └── AudioWaveformView.swift
└── Resources/
    ├── AppIcon.icns           — 波形柱图标
    ├── menubar_icon.png       — 菜单栏图标 PNG
    └── Assets.xcassets/       — 图标资源
```

## 功能清单

### 核心
- 按住右 ⌥ 说话，松开自动粘贴（按住模式）
- 按一次右 ⌥ 开始，再按一次停止（切换模式，适合长段落）
- 6 种 Whisper 模型（tiny → large-v3），根据内存自动推荐
- 繁简中文自动转换（简体/繁体/不转换）
- 翻译模式（说中文输出英文）
- 29 种语言

### AI 对话优化（v1.2.0）
- **代码术语保护** — 自定义词汇表，LLM 润色时保持原样
- **转写历史** — 最近 20 条，点击复制，持久化存储
- **连续听写** — 切换模式，5 分钟自动停止安全限制
- **取消操作** — 录音/识别中按 Esc 或点击悬浮条 ✕ 取消

### 可靠性
- 静音检测（RMS < 0.005 跳过）
- noSpeechThreshold 0.8
- 中英文幻觉过滤词库
- 模型完整性深度校验（检查 weights 文件）
- 启动时自动清理不完整下载
- 模型加载失败 → 显示重新下载/切换模型按钮
- 模型下载完成系统通知

### UI
- FlowBar 黑底/白底主题，idle 隐藏
- 首次启动三步引导
- 中英双语设置界面
- 焦点色跟随系统
- Ollama 状态实时检测
- 波形柱 App 图标 + 菜单栏图标

## 关键踩坑

- **必须 `--arch arm64` 编译**，否则 Rosetta 下 CoreML large 模型崩溃
- 每次重新编译签名后辅助功能权限失效
- NSImage 自定义菜单栏图标在 release 构建不渲染 → 改用 PNG 资源
- SwiftUI Picker 在 MenuBarExtra 里不会因数据变化自动刷新标签文字 → 用 `.id()` 强制
- WhisperKit 下载目录会自动创建 `models/argmaxinc/whisperkit-coreml/` 路径（两层 models 是正常的）
- `isModelDownloaded` 不能只检查目录存在，要检查 weights/weight.bin 或 coremldata.bin

## 下一步

- [ ] 自动发送（检测 AI 聊天框自动按回车）
- [ ] Prompt 模板（语音触发预设 prompt）
- [ ] 上下文感知（根据前台 app 调整润色风格）
- [ ] 菜单栏图标录音动画
- [ ] 白底 FlowBar 阴影裁剪问题
- [ ] Homebrew cask（可选）
