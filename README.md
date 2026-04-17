# Murmur

[English](#murmur-english) | [中文](#murmur-中文)

---

# Murmur (English)

A local voice-to-text tool for macOS, designed to make communicating with AI agents easier. Hold a key, speak, release — text appears at your cursor.

All speech recognition runs on-device via [WhisperKit](https://github.com/argmaxinc/WhisperKit). Nothing leaves your Mac.

## Features

- Hold Right ⌥ to speak, release to paste. Or toggle mode: press to start, press to stop
- 6 Whisper models (Tiny 39MB → Large v3 3GB), auto-recommended by RAM
- Optional text polish via local [Ollama](https://ollama.com) LLM
- Simplified/Traditional Chinese auto-conversion
- Translation: speak Chinese, output English
- Voice commands: "new line", "send", "delete", "undo", "select all"
- Transcription history (last 20 records)
- Custom protected terms for code/technical vocabulary
- 29 languages supported
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

## Text Polish (Optional)

```bash
ollama pull qwen2.5:1.5b
```

Enable in settings. Fixes punctuation, removes filler words, preserves code terms.

## Requirements

- macOS 14.0+
- Apple Silicon (M1/M2/M3/M4)
- Xcode (build from source only)

## Credits

Forked from [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) (MIT License).

## License

MIT

---

# Murmur (中文)

macOS 本地语音转文字工具，目标是让用户与 AI 代理的沟通更自然。按住说话，松开出字，文字自动粘贴到光标处。

所有语音识别通过 [WhisperKit](https://github.com/argmaxinc/WhisperKit) 在本地运行，不上传任何数据。

## 功能

- 按住右 ⌥ 说话，松开粘贴。或切换模式：按一次开始，再按一次停止
- 6 种 Whisper 模型（Tiny 39MB → Large v3 3GB），根据内存自动推荐
- 可选本地 LLM（Ollama）文本润色
- 繁简中文自动转换
- 翻译模式：说中文，输出英文
- 语音指令："换行""发送""删除""撤销""全选"
- 转写历史（最近 20 条）
- 自定义保护术语，润色时保持代码词不变
- 支持 29 种语言
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

## 文本润色（可选）

```bash
ollama pull qwen2.5:1.5b
```

在设置中开启，自动修正标点、去除口语词、保护代码术语。

## 系统要求

- macOS 14.0+
- Apple Silicon（M1/M2/M3/M4）
- Xcode（仅源码编译需要）

## 致谢

Fork 自 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app)（MIT License）。

## License

MIT
