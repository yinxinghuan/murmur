# Murmur

**macOS 本地语音转文字** — 按住说话，松开出字。100% 离线，免费开源。

**Local voice-to-text for macOS** — Hold a key, speak, release. Text appears at your cursor. 100% offline, free and open source.

基于 [WhisperKit](https://github.com/argmaxinc/WhisperKit)（OpenAI Whisper 的 Apple Silicon 优化版），所有语音识别在本地完成，不上传任何数据。

Built on [WhisperKit](https://github.com/argmaxinc/WhisperKit) (OpenAI Whisper optimized for Apple Silicon). All speech recognition runs locally — no data ever leaves your Mac.

---

## 功能 / Features

- **按住说话** — 按住右 ⌥（Option），说话，松开，文字自动粘贴到光标处
- **100% 本地** — 无需网络，语音不离开你的电脑
- **中文优化** — 默认中文，支持 large-v3 模型，繁简自动转换
- **文本润色** — 可选本地 LLM（Ollama）自动修正标点、去除口语填充词
- **翻译模式** — 说中文，直接输出英文（Whisper 内置翻译）
- **29 种语言** — 中文、英文、日文、韩文、法文、德文等
- **黑白主题** — 悬浮录音条支持黑底/白底两种风格
- **中英双语界面** — 设置面板支持中文和英文
- **轻量** — 应用仅 6MB，空闲时 <100MB 内存

---

## 相较原版的改进 / Improvements over OpenWhisper

Murmur fork 自 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app)，在其基础上做了大量改进：

### 模型与识别
- **新增 Large v3 / Large v3 Turbo 模型支持**，中文识别质量大幅提升
- **智能模型推荐** — 根据系统内存自动推荐最适合的模型
- **模型完整性校验** — 深度检查模型文件，自动清理下载中断的损坏文件
- **模型加载失败处理** — 提供"重新下载"和"切换模型"选择，不再静默降级
- **模型下载完成通知** — 系统通知提醒，无需盯着设置面板
- **繁简中文自动转换** — 可选输出简体/繁体/不转换，零延迟
- **中文幻觉过滤** — 大幅扩充过滤词库（中英文 YouTube 片尾语、字幕组署名等）
- **静音检测** — 无声录音直接跳过，不触发 Whisper，彻底减少幻觉

### LLM 文本润色
- **LLM 模型可选** — 设置面板中选择 Ollama 模型，不再硬编码
- **中文优化 Prompt** — 简体中文标点、中英混合保留、去除中文口语填充词
- **Ollama 状态实时检测** — 每次打开面板刷新连接状态

### 交互与界面
- **全新 FlowBar** — 黑底/白底两种高对比度主题，idle 时隐藏
- **首次启动引导** — 三步引导：操作说明 → 权限授予 → 模型下载
- **翻译模式** — 输出选项"原文/译为英文"，输入语言为英文时自动隐藏
- **声音反馈** — 开始/停止/完成/错误各有低音量提示音
- **中英双语设置界面** — 一键切换
- **焦点色跟随系统** — 适配用户偏好
- **自定义 App 图标** — 波形柱设计

### 可靠性
- **ARM64 原生构建** — 不再通过 Rosetta 运行，CoreML 性能最优
- **noSpeechThreshold 调优** — 减少 Whisper 空音频幻觉
- **启动时自动清理** — 删除不完整的模型下载
- **模型目录 README** — 告知用户支持的模型和手动添加方法

---

## 安装 / Install

### 下载安装（推荐）/ Download (Recommended)

从 [Releases](https://github.com/yinxinghuan/murmur/releases) 下载最新 `.dmg`，打开后将 Murmur 拖入 Applications。

Download the latest `.dmg` from [Releases](https://github.com/yinxinghuan/murmur/releases), open it and drag Murmur to Applications.

### 从源码编译 / Build from Source

需要 Xcode 和 Apple Silicon Mac。Requires Xcode and Apple Silicon Mac.

```bash
git clone https://github.com/yinxinghuan/murmur.git
cd murmur
bash build.sh
cp -R build/Murmur.app /Applications/
```

## 首次使用 / Getting Started

1. 启动 Murmur — 它在菜单栏，没有 Dock 图标 / Launch Murmur — it's in the menu bar, no Dock icon
2. 授予**麦克风**权限 / Grant **Microphone** permission
3. 授予**辅助功能**权限（系统设置 → 隐私与安全性 → 辅助功能）/ Grant **Accessibility** (System Settings → Privacy & Security → Accessibility)
4. 等待模型下载完成 / Wait for model download to complete
5. **按住右 ⌥ 说话，松开即可** / **Hold Right ⌥ to speak, release to paste**

## 语音模型 / Voice Models

| 模型 Model | 大小 Size | 速度 Speed | 中文 Chinese |
|------|------|------|---------|
| Tiny | 39 MB | ★★★★★ | ★★ |
| Base | 140 MB | ★★★★ | ★★ |
| Small | 460 MB | ★★★ | ★★★（默认 default） |
| Large v3 Turbo | 1.6 GB | ★★★ | ★★★★ |
| Large v3 | 3 GB | ★★ | ★★★★★ |

系统根据你的 Mac 内存自动推荐最适合的模型。

The app auto-recommends the best model based on your Mac's RAM.

## 文本润色（可选）/ Text Polish (Optional)

安装 [Ollama](https://ollama.com) 后拉取模型 / Install [Ollama](https://ollama.com) then pull a model:

```bash
ollama pull qwen2.5:1.5b
```

Murmur 会自动检测 Ollama，在设置中开启"文本润色"即可。

Murmur auto-detects Ollama. Enable "Text polish" in settings.

## 系统要求 / Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4)
- Xcode (only for building from source)

## 致谢 / Credits

Fork 自 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) by Rajvardhman05 (MIT License)。感谢原作者提供了优秀的基础框架。

Forked from [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app) by Rajvardhman05 (MIT License). Thanks for the excellent foundation.

## License

MIT
