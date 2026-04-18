# Murmur

[English](#murmur-english) | [中文](#murmur-中文)

---

# Murmur (English)

Local voice-to-text for macOS, built for talking to AI. Hold a key, speak, release — text appears at your cursor.

All processing runs on-device. Nothing leaves your Mac.

## How It Works

1. Hold **Right ⌥** and speak (or press once to start, again to stop)
2. [WhisperKit](https://github.com/argmaxinc/WhisperKit) transcribes your speech locally
3. [Ollama](https://ollama.com) LLM polishes the text (optional)
4. Result is auto-pasted at your cursor

Press **Esc** or tap **✕** on the Flow Bar to cancel anytime.

## Features

**Speech Recognition**
- 6 Whisper models: Tiny (39 MB) → Large v3 (3 GB), auto-recommended by RAM
- 7 languages: Chinese, English, Japanese, Korean, Spanish, French, German + auto-detect
- Simplified/Traditional Chinese conversion
- Translation mode: speak Chinese, output English

**Text Polish** (requires [Ollama](https://ollama.com))
- **Auto** (default) — LLM intelligently decides: clean punctuation, compress verbosity, or structure into lists
- **Spoken** — Only adds punctuation, keeps every word
- **Natural** — Removes filler words (嗯, 那个, um, like), fixes punctuation
- **Concise** — Compresses to core intent, saves tokens
- **Structured β** — Converts multi-step speech into numbered lists
- **Custom** — Write your own polish prompt
- Switch styles from the Flow Bar during recording
- Protected terms: tag picker with quick-add suggestions (API, React, Docker, etc.)
- Translation mode automatically skips polish to preserve English output

**LLM Models**
- Default: qwen2.5:3b (recommended). Also supports 1.5b and 7b
- Auto-downloads when you select an uninstalled model
- 1.5b limits to Spoken/Natural styles only (larger models needed for others)

**UI**
- Menu bar app — no Dock icon, always accessible
- Flow Bar: dark/light theme, shows recording time, style badge, cancel button
- Bilingual interface (Chinese/English)
- Update check on menu open

## Install

Build from source:

```bash
git clone https://github.com/yinxinghuan/murmur.git
cd murmur
bash build.sh
cp -R build/Murmur.app /Applications/
```

## Requirements

- macOS 14.0+
- Apple Silicon (M1/M2/M3/M4)
- [Ollama](https://ollama.com) (for text polish, optional)

## Credits

Forked from [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) by [Rajvardhman05](https://github.com/Rajvardhman05). MIT license.

---

# Murmur (中文)

macOS 本地语音转文字，专为与 AI 对话设计。按住说话，松开出字，自动粘贴到光标处。

所有处理在本地完成，不上传任何数据。

## 使用方式

1. 按住**右 ⌥** 说话（或按一次开始，再按一次停止）
2. [WhisperKit](https://github.com/argmaxinc/WhisperKit) 在本地转写语音
3. [Ollama](https://ollama.com) LLM 润色文本（可选）
4. 结果自动粘贴到光标位置

录音或识别中随时按 **Esc** 或点击悬浮条 **✕** 取消。

## 功能

**语音识别**
- 6 种 Whisper 模型：Tiny（39 MB）→ Large v3（3 GB），根据内存自动推荐
- 7 种语言：中文、英文、日语、韩语、西班牙语、法语、德语 + 自动检测
- 繁简中文自动转换
- 翻译模式：说中文，输出英文

**文本润色**（需要 [Ollama](https://ollama.com)）
- **自动**（默认）— LLM 智能判断：加标点、压缩冗余、或整理成列表
- **口语** — 只加标点，保留所有原话
- **自然** — 删除口语词（嗯、那个、就是），修正标点
- **精简** — 压缩到核心意图，节省 token
- **结构化 β** — 多步骤内容转为编号列表
- **自定义** — 编写自己的润色 prompt
- 录音时在悬浮条上快速切换风格
- 术语保护：标签选择器 + 常用技术术语快速添加（API、React、Docker 等）
- 翻译模式下自动跳过润色，保持英文输出

**LLM 模型**
- 默认：qwen2.5:3b（推荐），另支持 1.5b 和 7b
- 选择未安装的模型时自动下载
- 1.5b 仅支持口语和自然风格（其他风格需要更大模型）

**界面**
- 菜单栏应用，无 Dock 图标，随时可用
- 悬浮条：黑底/白底主题，显示录音时长、风格标签、取消按钮
- 中英双语界面
- 打开菜单自动检测新版本

## 安装

从源码编译：

```bash
git clone https://github.com/yinxinghuan/murmur.git
cd murmur
bash build.sh
cp -R build/Murmur.app /Applications/
```

## 系统要求

- macOS 14.0+
- Apple Silicon（M1/M2/M3/M4）
- [Ollama](https://ollama.com)（文本润色功能需要，可选）

## 致谢

Fork 自 [Rajvardhman05](https://github.com/Rajvardhman05) 的 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app)。MIT 协议。
