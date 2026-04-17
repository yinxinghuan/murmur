# Murmur

[English](#murmur-english) | [中文](#murmur-中文)

---

# Murmur (English)

**Voice-to-text for macOS, built for talking to AI.**

Hold a key, speak, release — text appears at your cursor. 100% local, 100% free.

## Why Murmur

- **Talk to AI, don't type** — Speak naturally to Claude, ChatGPT, Cursor, or any app. Voice is faster than typing for prompts, code reviews, and brainstorming.
- **100% offline** — Powered by [WhisperKit](https://github.com/argmaxinc/WhisperKit) on Apple Silicon. Your voice never leaves your Mac. No cloud, no subscription.
- **Smart text polish** — Optional local LLM (Ollama) fixes punctuation, removes filler words, and preserves your code terms exactly as-is.
- **Two modes** — Hold-to-talk for quick input. Toggle mode for long conversations with AI.
- **Voice commands** — Say "send", "new line", "delete" at the end of your speech. Hands-free AI interaction.

## Features

- **Hold or Toggle** — Hold Right ⌥ for quick input, or press once to start / press again to stop
- **6 Whisper models** — From Tiny (39 MB) to Large v3 (3 GB), auto-recommended for your Mac
- **Chinese optimized** — Simplified/Traditional auto-conversion, Chinese hallucination filtering
- **Translation** — Speak Chinese, output English
- **Text polish** — Local LLM removes "um", "uh", fixes grammar, preserves code terms
- **Voice commands** — "new line", "send", "delete", "undo", "select all"
- **Transcription history** — Last 20 records, tap to copy
- **Smart model management** — Integrity checks, auto-retry, download notifications
- **29 languages** — Chinese, English, Japanese, Korean, and more
- **Lightweight** — 6 MB app, <100 MB RAM when idle

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

1. Launch Murmur — it lives in your **menu bar**
2. Grant **Microphone** and **Accessibility** permissions
3. Wait for model download (~460 MB)
4. **Hold Right ⌥ to speak, release to paste**

## Voice Models

| Model | Size | Speed | Chinese |
|------|------|------|---------|
| Tiny | 39 MB | ★★★★★ | ★★ |
| Base | 140 MB | ★★★★ | ★★ |
| Small | 460 MB | ★★★ | ★★★ (default) |
| Large v3 Turbo | 1.6 GB | ★★★ | ★★★★ |
| Large v3 | 3 GB | ★★ | ★★★★★ |

Auto-recommended based on your Mac's RAM.

## Text Polish (Optional)

```bash
brew install ollama
ollama pull qwen2.5:1.5b
```

Enable "Text polish" in settings. Murmur auto-detects Ollama.

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4)

## Credits

Forked from [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) by Rajvardhman05 (MIT License).

## License

MIT

---

# Murmur (中文)

**macOS 语音转文字，专为与 AI 对话打造。**

按住说话，松开出字，文字自动粘贴到光标处。100% 本地运行，完全免费。

## 为什么选择 Murmur

- **用声音和 AI 对话** — 对 Claude、ChatGPT、Cursor 或任何应用说话。语音比打字更快，适合写 prompt、review 代码、头脑风暴。
- **100% 离线** — 基于 [WhisperKit](https://github.com/argmaxinc/WhisperKit)，在 Apple Silicon 上本地运行。语音不上传，无需订阅。
- **智能文本润色** — 可选本地 LLM（Ollama）自动修正标点、去除口语填充词，同时保护你的代码术语不被修改。
- **两种录音模式** — 按住模式适合快速输入，切换模式适合和 AI 长对话。
- **语音指令** — 说"发送""换行""删除"，无需触碰键盘。

## 功能

- **按住或切换** — 按住右 ⌥ 快速输入，或按一次开始、再按一次停止
- **6 种 Whisper 模型** — 从 Tiny（39 MB）到 Large v3（3 GB），根据内存自动推荐
- **中文优化** — 繁简自动转换、中文幻觉过滤、中文标点修正
- **翻译模式** — 说中文，输出英文
- **文本润色** — 本地 LLM 去除"嗯""啊"，修正语法，保护代码术语
- **语音指令** — "换行""发送""删除""撤销""全选"
- **转写历史** — 最近 20 条记录，点击复制
- **智能模型管理** — 完整性校验、失败重试、下载完成通知
- **29 种语言** — 中文、英文、日文、韩文等
- **轻量** — 应用仅 6 MB，空闲时 <100 MB 内存

## 安装

### 下载安装（推荐）

从 [Releases](https://github.com/yinxinghuan/murmur/releases) 下载最新 `.dmg`，拖入 Applications。

### 从源码编译

需要 Xcode 和 Apple Silicon Mac。

```bash
git clone https://github.com/yinxinghuan/murmur.git
cd murmur
bash build.sh
cp -R build/Murmur.app /Applications/
```

## 首次使用

1. 启动 Murmur — 在菜单栏，没有 Dock 图标
2. 授予**麦克风**和**辅助功能**权限
3. 等待模型下载（约 460 MB）
4. **按住右 ⌥ 说话，松开即可**

## 语音模型

| 模型 | 大小 | 速度 | 中文效果 |
|------|------|------|---------|
| Tiny | 39 MB | ★★★★★ | ★★ |
| Base | 140 MB | ★★★★ | ★★ |
| Small | 460 MB | ★★★ | ★★★（默认） |
| Large v3 Turbo | 1.6 GB | ★★★ | ★★★★ |
| Large v3 | 3 GB | ★★ | ★★★★★ |

根据 Mac 内存自动推荐。

## 文本润色（可选）

```bash
brew install ollama
ollama pull qwen2.5:1.5b
```

在设置中开启"文本润色"，Murmur 会自动检测 Ollama。

## 系统要求

- macOS 14.0（Sonoma）或更高
- Apple Silicon（M1/M2/M3/M4）

## 致谢

Fork 自 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) by Rajvardhman05（MIT License）。

## License

MIT
