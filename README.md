# Murmur

[English](#murmur-english) | [中文](#murmur-中文)

---

# Murmur (English)

A local voice-to-text tool for macOS, designed to make communicating with AI agents easier. Hold a key, speak, release — text appears at your cursor.

All speech recognition runs on-device via [WhisperKit](https://github.com/argmaxinc/WhisperKit). Nothing leaves your Mac.

## Features

- Hold Right ⌥ to speak, release to paste. Or toggle mode: press to start, press to stop
- 6 Whisper models (Tiny 39MB → Large v3 3GB), auto-recommended by RAM
- Text polish via local [Ollama](https://ollama.com) LLM with 4 styles: Spoken, Natural, Concise, Structured
- Custom polish style: write your own prompt
- Switch polish style from Flow Bar during recording
- Simplified/Traditional Chinese auto-conversion
- Translation: speak Chinese, output English
- Transcription history (last 20 records)
- Protected terms: tag-based picker with quick-add suggestions for common tech terms
- Cancel anytime: press Esc or tap ✕ on the Flow Bar during recording/transcription
- Auto-download LLM models when selected
- 7 languages: Chinese, English, Japanese, Korean, Spanish, French, German + auto-detect
- Menu bar app, 6 MB, <100 MB RAM idle

## Install

Download `.dmg` from [Releases](https://github.com/yinxinghuan/murmur/releases), or build from source:

```bash
git clone https://github.com/yinxinghuan/murmur.git
cd murmur
bash build.sh
cp -R build/Murmur.app /Applications/
```

## Getting Started

1. Launch Murmur (menu bar, no Dock icon)
2. Grant Microphone and Accessibility permissions
3. Wait for model download (~460 MB)
4. Hold Right ⌥, speak, release

## Models

| Model | Size | Speed | Chinese |
|-------|------|-------|---------|
| Tiny | 39 MB | ★★★★★ | ★★ |
| Base | 140 MB | ★★★★ | ★★ |
| Small | 460 MB | ★★★ | ★★★ (default) |
| Large v3 Turbo | 1.6 GB | ★★★ | ★★★★ |
| Large v3 | 3 GB | ★★ | ★★★★★ |

## Text Polish

```bash
ollama pull qwen2.5:3b
```

Enable in settings. 4 polish styles:

| Style | Effect |
|-------|--------|
| Spoken | Only adds punctuation, keeps all words |
| Natural | Removes filler words, fixes punctuation |
| Concise | Compresses to core intent, saves tokens |
| Structured β | Converts multi-step speech to numbered list |

Default model: qwen2.5:3b (recommended). Selecting an uninstalled model auto-downloads it.

## Requirements

- macOS 14.0+
- Apple Silicon (M1/M2/M3/M4)
- Xcode (build from source only)

## What's Different from OpenWhisper

Murmur is forked from [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) and adds:

- Large v3 / Large v3 Turbo model support
- Toggle dictation mode for long conversations
- 4 polish styles with Flow Bar quick-switch
- Protected terms with tag picker and quick-add suggestions
- Cancel recording/transcription anytime (Esc or Flow Bar ✕)
- Auto-download LLM models
- Transcription history
- Chinese optimization: Simplified/Traditional conversion, hallucination filtering
- Silent audio detection, language mismatch detection with user notification
- Model integrity checks, download failure recovery
- Redesigned settings with basic/advanced split
- Bilingual UI (Chinese/English)

## Credits

Thanks to [Rajvardhman05](https://github.com/Rajvardhman05) for creating OpenWhisper — the solid foundation this project builds on.

## License

MIT

---

# Murmur (中文)

macOS 本地语音转文字工具，目标是让用户与 AI 代理的沟通更自然。按住说话，松开出字，文字自动粘贴到光标处。

所有语音识别通过 [WhisperKit](https://github.com/argmaxinc/WhisperKit) 在本地运行，不上传任何数据。

## 功能

- 按住右 ⌥ 说话，松开粘贴。或切换模式：按一次开始，再按一次停止
- 6 种 Whisper 模型（Tiny 39MB → Large v3 3GB），根据内存自动推荐
- 本地 LLM（Ollama）文本润色，4 种风格：口语、自然、精简、结构化
- 自定义润色风格：编写自己的 prompt
- 录音时在悬浮条上快速切换润色风格
- 繁简中文自动转换
- 翻译模式：说中文，输出英文
- 转写历史（最近 20 条）
- 术语保护：标签式选择器 + 常用技术术语快速添加
- 随时取消：录音/识别中按 Esc 或点击悬浮条 ✕
- 选择未安装的 LLM 模型时自动下载
- 支持 7 种语言：中文、英文、日语、韩语、西班牙语、法语、德语 + 自动检测
- 菜单栏应用，6 MB，空闲 <100 MB 内存

## 安装

从 [Releases](https://github.com/yinxinghuan/murmur/releases) 下载 `.dmg`，或从源码编译：

```bash
git clone https://github.com/yinxinghuan/murmur.git
cd murmur
bash build.sh
cp -R build/Murmur.app /Applications/
```

## 使用

1. 启动 Murmur（菜单栏，无 Dock 图标）
2. 授予麦克风和辅助功能权限
3. 等待模型下载（约 460 MB）
4. 按住右 ⌥ 说话，松开即可

## 模型

| 模型 | 大小 | 速度 | 中文效果 |
|------|------|------|---------|
| Tiny | 39 MB | ★★★★★ | ★★ |
| Base | 140 MB | ★★★★ | ★★ |
| Small | 460 MB | ★★★ | ★★★（默认） |
| Large v3 Turbo | 1.6 GB | ★★★ | ★★★★ |
| Large v3 | 3 GB | ★★ | ★★★★★ |

## 文本润色

```bash
ollama pull qwen2.5:3b
```

在设置中开启。4 种润色风格：

| 风格 | 效果 |
|------|------|
| 口语 | 只加标点，保留所有原话 |
| 自然 | 删除口语词，修正标点 |
| 精简 | 压缩冗余，直达意图，节省 token |
| 结构化 β | 多步骤口语转有序列表 |

默认模型：qwen2.5:3b（推荐）。选择未安装的模型会自动下载。

## 系统要求

- macOS 14.0+
- Apple Silicon（M1/M2/M3/M4）
- Xcode（仅源码编译需要）

## 相较 OpenWhisper 的改进

Murmur fork 自 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app)，主要改进：

- 新增 Large v3 / Large v3 Turbo 模型支持
- 切换录音模式，适合长对话
- 4 种润色风格 + 悬浮条快速切换
- 术语保护：标签式选择器 + 常用术语快速添加
- 随时取消录音/识别（Esc 或悬浮条 ✕）
- LLM 模型自动下载
- 转写历史
- 中文优化：繁简转换、幻觉过滤
- 静音检测、语言不匹配检测（含用户通知）
- 模型完整性校验、下载失败恢复
- 设置面板分层（基础/高级）
- 中英双语界面

## 致谢

感谢 [Rajvardhman05](https://github.com/Rajvardhman05) 创建了 OpenWhisper，为本项目提供了优秀的基础。

## License

MIT
