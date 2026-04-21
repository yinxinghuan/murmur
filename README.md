# Murmur

[English](#murmur--local-voice-to-text-for-macos) | [中文](#murmur--macos-本地语音转文字)

---

# Murmur — Local Voice-to-Text for macOS

A local, offline voice-to-text tool for macOS, built for talking to AI agents. Hold a key, speak, release — polished text appears at your cursor. All processing stays on your Mac.

Forked from [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) (MIT), rebuilt with a focus on Chinese + English workflows, intelligent text polishing, and a more complete desktop experience.

## How It Works

1. Hold **Right ⌥** and speak (or press once to start, again to stop)
2. [WhisperKit](https://github.com/argmaxinc/WhisperKit) transcribes your speech locally
3. [Ollama](https://ollama.com) LLM polishes the text (optional)
4. Result is auto-pasted at your cursor

Press **Esc** or tap **✕** on the Flow Bar to cancel anytime.

## What's New vs OpenWhisper

OpenWhisper is a clean, minimal voice-to-text app. Murmur keeps that foundation and adds:

| | OpenWhisper | Murmur |
|---|---|---|
| **Text Polish** | Basic grammar cleanup | 6 styles: Auto, Spoken, Natural, Concise, Structured, Custom |
| **Dictation Mode** | Hold only | Hold + Toggle (press-to-start/stop, for long dictation) |
| **Context Awareness** | — | Auto-switch polish style per app (e.g. concise in code editors) |
| **Term Protection** | — | Custom word list + smart auto-detect of mangled terms |
| **Transcription History** | — | Searchable history with raw vs polished diff |
| **Chinese Support** | Basic | Simplified/Traditional conversion, Chinese hallucination filters |
| **Model Management** | Download & use | Integrity checks, auto-cleanup, delete, progress phases |
| **Notification** | — | Toast bubbles, paste failure feedback, download alerts |
| **UI** | Settings panel | Full dashboard with stats, sidebar navigation, menu bar dropdown |
| **LLM Models** | Generic | Qwen2.5 (1.5b/3b/7b), auto-download, model-aware style limits |

## Features

### Speech Recognition
- **6 Whisper models**: Tiny (39 MB) → Large v3 (3 GB), auto-recommended by your RAM
- **29 languages**: Chinese, English, Japanese, Korean, Spanish, French, German, Italian, Portuguese, Russian, Arabic, Hindi, Turkish, Polish, Dutch, Swedish, Danish, Norwegian, Finnish, Czech, Romanian, Hungarian, Greek, Hebrew, Thai, Vietnamese, Indonesian, Malay, Ukrainian + auto-detect
- **Chinese text processing**: Simplified/Traditional conversion, hallucination filtering (70+ patterns)
- **Translation mode**: Speak in any language, output English
- **Reliability**: Silent detection, min-length checks, word diversity validation, language mismatch auto-retry

### Text Polish (requires [Ollama](https://ollama.com))
- **Auto** (default) — LLM intelligently decides: clean punctuation, compress verbosity, or structure into lists
- **Spoken** — Only adds punctuation, keeps every word
- **Natural** — Removes filler words (嗯, 那个, um, like), fixes punctuation
- **Concise** — Compresses to core intent, saves tokens
- **Structured β** — Converts multi-step speech into numbered lists
- **Custom** — Write your own polish prompt
- Switch styles from the Flow Bar during recording
- **Protected terms**: Tag picker with smart suggestions — auto-detects technical terms the LLM modifies incorrectly
- **Context-aware**: Set per-app polish rules (e.g. "Concise" in VS Code, "Natural" in Notes)
- Translation mode automatically skips polish to preserve output

### LLM Models
- Default: **qwen2.5:3b** (recommended). Also supports 1.5b and 7b
- Auto-downloads when you select an uninstalled model
- Delete models from settings (calls Ollama API, clean removal)
- 1.5b limits to Spoken/Natural styles only (larger models needed for others)

### Input
- **Hold mode**: Hold Right ⌥ to record, release to stop
- **Toggle mode**: Press once to start, again to stop — good for long paragraphs, auto-stops after 5 minutes
- **Auto-paste**: Result injected at cursor via Cmd+V. Focus-loss detection prevents pasting into the wrong app
- **Cancel**: Esc key or Flow Bar ✕ button, anytime during recording or transcription

### UI
- **Menu bar app** — no Dock icon, always one click away
- **Flow Bar**: Dark / Light theme, shows recording time, audio level, style badge, cancel button. Red state on paste failure
- **Dashboard**: Stats cards (today's count, words, total), recent transcriptions, keyboard shortcuts
- **History**: Searchable, expandable rows showing raw vs polished text, copy & delete
- **Toast notifications**: Bubble with arrow anchored to menu bar icon — paste failures, download complete, errors
- **Bilingual interface**: Chinese / English, follows system locale
- **Update check**: Automatic on menu open, badge when new version available

### Voice Reminders
- Say "remind me to..." and Murmur parses the time and task via LLM
- Supports natural language: "in 2 hours", "tomorrow morning", "tonight"
- System notification fires at the scheduled time

## Strengths & Limitations

### Strengths
- **100% local** — No cloud, no API keys, no data leaves your Mac
- **Low friction** — One hotkey for the entire workflow, result lands at your cursor
- **Smart polish** — Not just transcription; the LLM cleans up speech into readable text, with style control
- **Chinese-first** — Hallucination filtering, simplified/traditional conversion, Chinese-aware LLM prompts
- **Context-aware** — Different polish styles for different apps, automatically

### Limitations
- **Apple Silicon only** — No Intel Mac support (CoreML / WhisperKit limitation)
- **macOS 14+ required**
- **Right ⌥ only** — Hotkey is not configurable
- **Ollama required for polish** — Without it, you get raw transcription only
- **No code signing** — First launch triggers Gatekeeper warning (right-click → Open to bypass)
- **Whisper auto-detect can be unreliable** — Setting a specific language gives better results
- **Large models are slow on base M1** — Stick with tiny/base/small for responsive transcription

## Install

### From DMG (recommended)

Download the latest `.dmg` from [Releases](https://github.com/yinxinghuan/murmur/releases/latest), open it, and drag Murmur to Applications.

### Build from source

```bash
git clone https://github.com/yinxinghuan/murmur.git
cd murmur
bash build.sh
cp -R build/Murmur.app /Applications/
```

## Requirements

- macOS 14.0+
- Apple Silicon (M1 / M2 / M3 / M4)
- [Ollama](https://ollama.com) (for text polish, optional)

## Credits

Forked from [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) by [Rajvardhman05](https://github.com/Rajvardhman05). MIT license.

---

# Murmur — macOS 本地语音转文字

macOS 本地语音转文字工具，专为与 AI 对话设计。按住说话，松开出字，自动粘贴到光标处。所有处理在本地完成，不上传任何数据。

Fork 自 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app)（MIT），针对中英文场景重新打造，加入智能润色、上下文感知和完整桌面体验。

## 使用方式

1. 按住 **右 ⌥** 说话（或按一次开始，再按一次停止）
2. [WhisperKit](https://github.com/argmaxinc/WhisperKit) 在本地转写语音
3. [Ollama](https://ollama.com) LLM 润色文本（可选）
4. 结果自动粘贴到光标位置

录音或识别中随时按 **Esc** 或点击悬浮条 **✕** 取消。

## 相比 OpenWhisper 的改进

OpenWhisper 是一个简洁的语音转文字工具。Murmur 在此基础上增加了：

| | OpenWhisper | Murmur |
|---|---|---|
| **文本润色** | 基础语法修正 | 6 种风格：自动、口语、自然、精简、结构化、自定义 |
| **听写模式** | 仅按住 | 按住 + 切换（按一次开始/再按停止，适合长段落） |
| **上下文感知** | — | 根据前台应用自动切换润色风格 |
| **术语保护** | — | 自定义词表 + 智能检测被 LLM 错改的术语 |
| **转写历史** | — | 可搜索，支持查看原文与润色后对比 |
| **中文支持** | 基础 | 繁简转换、中文幻觉过滤 |
| **模型管理** | 下载即用 | 完整性校验、自动清理、删除、分阶段进度 |
| **通知系统** | — | Toast 气泡、粘贴失败反馈、下载完成提醒 |
| **界面** | 设置面板 | 完整仪表盘、侧边栏导航、菜单栏下拉 |
| **LLM 模型** | 通用 | Qwen2.5（1.5b/3b/7b），自动下载，按模型限制风格 |

## 功能

### 语音识别
- **6 种 Whisper 模型**：Tiny（39 MB）→ Large v3（3 GB），根据内存自动推荐
- **29 种语言**：中文、英文、日语、韩语、西班牙语、法语、德语、意大利语、葡萄牙语、俄语、阿拉伯语、印地语、土耳其语、波兰语、荷兰语、瑞典语、丹麦语、挪威语、芬兰语、捷克语、罗马尼亚语、匈牙利语、希腊语、希伯来语、泰语、越南语、印尼语、马来语、乌克兰语 + 自动检测
- **中文处理**：繁简转换、幻觉过滤（70+ 模式）
- **翻译模式**：说任意语言，输出英文
- **可靠性**：静音检测、最短长度、词汇多样性校验、语言不匹配自动重试

### 文本润色（需要 [Ollama](https://ollama.com)）
- **自动**（默认）— LLM 智能判断：加标点、压缩冗余、或整理成列表
- **口语** — 只加标点，保留所有原话
- **自然** — 删除口语词（嗯、那个、就是），修正标点
- **精简** — 压缩到核心意图，节省 token
- **结构化 β** — 多步骤内容转为编号列表
- **自定义** — 编写自己的润色 prompt
- 录音时在悬浮条上快速切换风格
- **术语保护**：标签选择器 + 智能建议 — 自动检测被 LLM 错改的技术术语
- **上下文感知**：为不同应用设置不同润色风格（如 VS Code 用精简，备忘录用自然）
- 翻译模式下自动跳过润色

### LLM 模型
- 默认：**qwen2.5:3b**（推荐），另支持 1.5b 和 7b
- 选择未安装的模型时自动下载
- 可在设置中删除模型（调用 Ollama API，干净删除）
- 1.5b 仅支持口语和自然风格（其他风格需要更大模型）

### 输入
- **按住模式**：按住右 ⌥ 录音，松开停止
- **切换模式**：按一次开始，再按一次停止 — 适合长段落，5 分钟自动停止
- **自动粘贴**：通过 Cmd+V 注入光标位置，检测焦点丢失避免粘错窗口
- **取消**：录音或转写中随时按 Esc 或点击悬浮条 ✕

### 界面
- **菜单栏应用** — 无 Dock 图标，随时可用
- **悬浮条**：深色 / 浅色主题，显示录音时长、音频电平、风格标签、取消按钮。粘贴失败时变红
- **仪表盘**：统计卡片（今日次数、字数、总记录），最近转写，快捷键提示
- **历史记录**：可搜索，展开查看原文与润色对比，复制和删除
- **Toast 通知**：锚定菜单栏图标的气泡 — 粘贴失败、下载完成、错误提醒
- **中英双语界面**，跟随系统语言
- **更新检测**：打开菜单自动检查，有新版本显示角标

### 语音提醒
- 说"提醒我……"，Murmur 通过 LLM 解析时间和任务
- 支持自然语言："两小时后"、"明天早上"、"今晚"
- 到时间后发送系统通知

## 优点与局限

### 优点
- **完全本地** — 无云端、无 API Key、数据不离开你的 Mac
- **低摩擦** — 一个快捷键完成整个流程，结果直接出现在光标处
- **智能润色** — 不只是转写；LLM 把口语整理成可读文本，可控制风格
- **中文优先** — 幻觉过滤、繁简转换、中文优化的 LLM 提示词
- **上下文感知** — 不同应用自动使用不同润色风格

### 局限
- **仅支持 Apple Silicon** — 不支持 Intel Mac（CoreML / WhisperKit 限制）
- **需要 macOS 14+**
- **快捷键固定为右 ⌥** — 不可自定义
- **润色需要 Ollama** — 没有 Ollama 只能获得原始转写
- **未签名** — 首次打开会触发 Gatekeeper 警告（右键 → 打开 即可绕过）
- **Whisper 自动检测语言不够可靠** — 指定语言效果更好
- **大模型在基础 M1 上较慢** — 建议使用 tiny/base/small 保证响应速度

## 安装

### DMG 安装（推荐）

从 [Releases](https://github.com/yinxinghuan/murmur/releases/latest) 下载最新 `.dmg`，打开后将 Murmur 拖入 Applications。

### 从源码编译

```bash
git clone https://github.com/yinxinghuan/murmur.git
cd murmur
bash build.sh
cp -R build/Murmur.app /Applications/
```

## 系统要求

- macOS 14.0+
- Apple Silicon（M1 / M2 / M3 / M4）
- [Ollama](https://ollama.com)（文本润色功能需要，可选）

## 致谢

Fork 自 [Rajvardhman05](https://github.com/Rajvardhman05) 的 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app)。MIT 协议。
