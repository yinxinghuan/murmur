# Murmur

**macOS 本地语音转文字** — 按住说话，松开出字。100% 离线，免费开源。

基于 [WhisperKit](https://github.com/argmaxinc/WhisperKit)（OpenAI Whisper 的 Apple Silicon 优化版），所有语音识别在本地完成，不上传任何数据。

## 功能

- **按住说话** — 按住右 ⌥（Option），说话，松开，文字自动粘贴到光标处
- **100% 本地** — 无需网络，语音不离开你的电脑
- **中文优化** — 默认中文，支持 large-v3 模型，中文标点和简体输出
- **文本润色** — 可选本地 LLM（Ollama）自动修正标点、去除口语填充词
- **翻译模式** — 说中文，直接输出英文
- **29 种语言** — 中文、英文、日文、韩文、法文、德文等
- **黑白主题** — 悬浮录音条支持黑底/白底两种风格
- **轻量** — 应用仅 6MB，空闲时 <100MB 内存

## 安装

### 下载安装（推荐）

从 [Releases](https://github.com/yinxinghuan/murmur/releases) 下载 `Murmur-1.0.0.dmg`，打开后将 Murmur 拖入 Applications。

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
| Tiny | 39 MB | 最快 | 一般 |
| Base | 140 MB | 快 | 一般 |
| Small | 460 MB | 中等 | 较好（默认） |
| Large v3 Turbo | 1.6 GB | 中等 | 很好 |
| Large v3 | 3 GB | 较慢 | 最好 |

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

Fork 自 [OpenWhisper](https://github.com/Rajvardhman05/openwhisper-app)（MIT License）。

## License

MIT
