# Murmur — macOS 本地语音转文字

Fork of [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app)，MIT 协议。
目标：做一个精致版的中文语音输入工具并发布。

## Tech Stack

- Swift / SwiftUI, macOS 14+, Apple Silicon (ARM64)
- SPM (Swift Package Manager), WhisperKit 0.9+
- Ollama (本地 LLM 清理)

## Build

```bash
swift build -c debug --arch arm64
# 必须 --arch arm64，否则默认 x86 + Rosetta 会导致 CoreML 崩溃
```

打包 .app:
```bash
cp .build/arm64-apple-macosx/debug/OpenWhisper build/OpenWhisper.app/Contents/MacOS/
cp OpenWhisper/Info.plist build/OpenWhisper.app/Contents/
codesign --force --deep --sign - build/OpenWhisper.app
cp -R build/OpenWhisper.app /Applications/
```

## 项目结构

```
OpenWhisper/
├── App/AppState.swift       — 全局状态、录音流程、设置持久化
├── App/OpenWhisperApp.swift — 入口
├── Core/
│   ├── AudioEngine.swift    — 麦克风采集 + 16kHz 重采样
│   ├── WhisperTranscriber.swift — WhisperKit 模型加载与转写
│   ├── LLMCleanup.swift     — Ollama LLM 标点/语法清理
│   ├── TextInjector.swift   — 自动粘贴 (CGEvent Cmd+V)
│   └── ReminderManager.swift
├── Hotkey/GlobalHotkey.swift — 右 Option 键监听
├── UI/
│   ├── FlowBarView.swift    — 3 主题 FlowBar (极简/毛玻璃/极光)
│   ├── FlowBarWindow.swift  — NSPanel 浮窗控制
│   ├── SettingsView.swift   — 设置面板
│   └── AudioWaveformView.swift
└── Resources/               — 图标资源
```

## 相对原版的改动

### 功能
- 新增 large-v3 / large-v3_turbo Whisper 模型支持
- 默认语言中文，LLM prompt 适配中文（简体、标点、中英混合）
- LLM 模型可在设置 UI 中选择（不再硬编码）
- 模型下载状态标识（✓ 已下载 / ↓ 需下载）

### 交互 & UI
- FlowBar 三主题：极简(voiceFirst) / 毛玻璃(spatialGlass) / 极光(aurora)
- FlowBar idle 时完全隐藏，仅录音/转写时显示
- 声音反馈（低音量系统音）：开始 Tink / 停止 Pop / 完成 Glass / 错误 Sosumi
- 设置面板中新增 Theme 分段选择器、LLM Model 选择器

### 构建
- 必须 ARM64 编译（x86 + Rosetta 下 CoreML large 模型会崩溃）
- Info.plist 需手动复制到 .app bundle（build.sh 路径问题）

## 已知问题

- 每次重新编译签名后，macOS 辅助功能权限会失效，需重新授权
- Bundle ID 仍为 com.openwhisper.app，发布前需要改
- App 名称仍为 OpenWhisper，发布前需要重命名为 Murmur

## 下一步

- [ ] 重命名 OpenWhisper → Murmur（Bundle ID、UI 文字、目录名）
- [ ] 设置面板 UI 现代化改造
- [ ] App 图标设计
- [ ] Release 构建 + .dmg 打包
- [ ] 在 yinxinghuan GitHub 创建 murmur 仓库并发布
- [ ] Homebrew cask 发布（可选）
