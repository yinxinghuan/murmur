# Murmur

[English](#murmur-english) | [中文](#murmur-中文)

---

# Murmur (English)

**Local voice-to-text for macOS** — Hold a key, speak, release. Text appears at your cursor. 100% offline, free and open source.

Built on [WhisperKit](https://github.com/argmaxinc/WhisperKit) (OpenAI Whisper optimized for Apple Silicon). All speech recognition runs locally — no data ever leaves your Mac.

## Features

- **Hold to speak** — Hold Right ⌥ (Option), speak, release. Text auto-pastes at cursor
- **100% local** — No internet required. Your voice never leaves your Mac
- **Chinese optimized** — Default Chinese, large-v3 model support, auto Traditional/Simplified conversion
- **Text polish** — Optional local LLM (Ollama) fixes punctuation and removes filler words
- **Translation mode** — Speak Chinese, output English (built-in Whisper translation)
- **29 languages** — Chinese, English, Japanese, Korean, French, German, and more
- **Dark/Light theme** — Floating recording bar with two high-contrast themes
- **Bilingual UI** — Settings panel in Chinese and English
- **Lightweight** — 6MB app, <100MB RAM when idle

## Improvements over OpenWhisper

Murmur is forked from [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) with extensive improvements:

### Models & Recognition
- Added Large v3 / Large v3 Turbo model support for significantly better Chinese recognition
- Smart model recommendation based on system RAM
- Deep model integrity verification, auto-cleanup of interrupted downloads
- Clear "Re-download" and "Use another model" options on load failure
- System notification when model download completes
- Traditional/Simplified Chinese auto-conversion
- Expanded hallucination filter (Chinese + English YouTube outros, subtitle credits)
- Silent audio detection — skips Whisper entirely when no speech detected

### LLM Text Polish
- LLM model selectable in settings (no longer hardcoded)
- Chinese-optimized prompt — Simplified punctuation, mixed-language preservation
- Ollama connection status refreshed on each panel open

### Interaction & UI
- Redesigned FlowBar — Dark/Light high-contrast themes, hidden when idle
- First-launch onboarding — 3-step guide: usage → permissions → model
- Translation mode — Original/English output toggle
- Sound feedback — subtle audio cues for start/stop/done/error
- Bilingual settings (Chinese/English), one-click switch
- Accent color follows system preference
- Custom app icon

### Reliability
- Native ARM64 build — optimal CoreML performance
- Tuned noSpeechThreshold to reduce blank-audio hallucinations
- Auto-cleanup of incomplete model downloads on startup
- README file in model directory for manual model management

## Install

### Download (Recommended)

Download the latest `.dmg` from [Releases](https://github.com/yinxinghuan/murmur/releases), open it and drag Murmur to Applications.

### Build from Source

Requires Xcode and Apple Silicon Mac.

```bash
git clone https://github.com/yinxinghuan/murmur.git
cd murmur
bash build.sh
cp -R build/Murmur.app /Applications/
```

## Getting Started

1. Launch Murmur — it's in the menu bar, no Dock icon
2. Grant **Microphone** permission when prompted
3. Grant **Accessibility** permission (System Settings → Privacy & Security → Accessibility)
4. Wait for model download to complete (~460MB for default model)
5. **Hold Right ⌥ to speak, release to paste**

## Voice Models

| Model | Size | Speed | Chinese |
|------|------|------|---------|
| Tiny | 39 MB | ★★★★★ | ★★ |
| Base | 140 MB | ★★★★ | ★★ |
| Small | 460 MB | ★★★ | ★★★ (default) |
| Large v3 Turbo | 1.6 GB | ★★★ | ★★★★ |
| Large v3 | 3 GB | ★★ | ★★★★★ |

The app auto-recommends the best model based on your Mac's RAM.

## Text Polish (Optional)

Install [Ollama](https://ollama.com) and pull a model:

```bash
ollama pull qwen2.5:1.5b
```

Murmur auto-detects Ollama. Enable "Text polish" in settings.

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4)
- Xcode (only for building from source)

## Credits

Forked from [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) by Rajvardhman05 (MIT License). Thanks for the excellent foundation.

## License

MIT

---

# Murmur (中文)

**macOS 本地语音转文字** — 按住说话，松开出字。100% 离线，免费开源。

基于 [WhisperKit](https://github.com/argmaxinc/WhisperKit)（OpenAI Whisper 的 Apple Silicon 优化版），所有语音识别在本地完成，不上传任何数据。

## 功能

- **按住说话** — 按住右 ⌥（Option），说话，松开，文字自动粘贴到光标处
- **100% 本地** — 无需网络，语音不离开你的电脑
- **中文优化** — 默认中文，支持 large-v3 模型，繁简自动转换
- **文本润色** — 可选本地 LLM（Ollama）自动修正标点、去除口语填充词
- **翻译模式** — 说中文，直接输出英文（Whisper 内置翻译）
- **29 种语言** — 中文、英文、日文、韩文、法文、德文等
- **黑白主题** — 悬浮录音条支持黑底/白底两种风格
- **中英双语界面** — 设置面板支持中文和英文切换
- **轻量** — 应用仅 6MB，空闲时 <100MB 内存

## 相较原版的改进

Murmur fork 自 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app)，在其基础上做了大量改进：

### 模型与识别
- 新增 Large v3 / Large v3 Turbo 模型支持，中文识别质量大幅提升
- 智能模型推荐 — 根据系统内存自动推荐最适合的模型
- 模型完整性深度校验，自动清理下载中断的损坏文件
- 模型加载失败时提供"重新下载"和"切换模型"选择
- 模型下载完成后发送系统通知
- 繁简中文自动转换（简体/繁体/不转换三选一）
- 中英文幻觉过滤词库大幅扩充
- 静音检测 — 无声录音直接跳过，减少幻觉

### LLM 文本润色
- LLM 模型可在设置中选择，不再硬编码
- 中文优化 Prompt — 简体标点、中英混合保留、去除中文口语填充词
- Ollama 状态实时检测，每次打开面板刷新连接状态

### 交互与界面
- 全新 FlowBar — 黑底/白底两种高对比度主题，空闲时隐藏
- 首次启动三步引导 — 操作说明 → 权限授予 → 模型下载
- 翻译模式 — 输出选项支持原文/译为英文
- 声音反馈 — 开始/停止/完成/错误各有低音量提示音
- 中英双语设置界面，一键切换
- 焦点色跟随系统强调色
- 自定义 App 图标

### 可靠性
- ARM64 原生构建，CoreML 性能最优
- noSpeechThreshold 调优，减少空音频幻觉
- 启动时自动清理不完整的模型下载
- 模型目录内置 README 说明文件

## 安装

### 下载安装（推荐）

从 [Releases](https://github.com/yinxinghuan/murmur/releases) 下载最新 `.dmg`，打开后将 Murmur 拖入 Applications。

### 从源码编译

需要 Xcode 和 Apple Silicon Mac。

```bash
git clone https://github.com/yinxinghuan/murmur.git
cd murmur
bash build.sh
cp -R build/Murmur.app /Applications/
```

## 首次使用

1. 启动 Murmur — 它在菜单栏，没有 Dock 图标
2. 授予**麦克风**权限（弹窗提示）
3. 授予**辅助功能**权限（系统设置 → 隐私与安全性 → 辅助功能）
4. 等待模型下载完成（首次约 460MB）
5. **按住右 ⌥ 说话，松开即可**

## 语音模型

| 模型 | 大小 | 速度 | 中文效果 |
|------|------|------|---------|
| Tiny | 39 MB | ★★★★★ | ★★ |
| Base | 140 MB | ★★★★ | ★★ |
| Small | 460 MB | ★★★ | ★★★（默认） |
| Large v3 Turbo | 1.6 GB | ★★★ | ★★★★ |
| Large v3 | 3 GB | ★★ | ★★★★★ |

系统根据你的 Mac 内存自动推荐最适合的模型。

## 文本润色（可选）

安装 [Ollama](https://ollama.com) 后拉取模型：

```bash
ollama pull qwen2.5:1.5b
```

Murmur 会自动检测 Ollama，在设置中开启"文本润色"即可。

## 系统要求

- macOS 14.0（Sonoma）或更高
- Apple Silicon（M1/M2/M3/M4）
- Xcode（仅从源码编译时需要）

## 致谢

Fork 自 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) by Rajvardhman05（MIT License）。感谢原作者提供了优秀的基础框架。

## License

MIT

