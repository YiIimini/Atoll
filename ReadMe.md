<p align="center">
  <img src=".github/assets/atoll-logo.png" alt="Atoll logo" width="120">
</p>
<h1 align="center">Atoll — macOS 灵动岛</h1>

Atoll 将 MacBook 的刘海变成媒体控制、系统监控和快捷工具的集中操作台。未使用时安静隐藏，需要时展开为流畅的原生 SwiftUI 动画界面。

<p align="center">
  <img src="https://i.postimg.cc/t49mW5yN/Screenshot-2026-03-02-at-6-00-22-PM.png" alt="Atoll lock screen" width="920">
</p>

## 下载

本仓库提供两个版本：

| 版本 | 下载 | 说明 |
|---|---|---|
| **[原版](https://github.com/Ebullioscopic/Atoll/releases/latest)** | [Ebullioscopic/Atoll Releases](https://github.com/Ebullioscopic/Atoll/releases/latest) | 上游英文原版，持续更新 |
| **[中文优化版](https://github.com/YiIimini/Atoll/releases)** | [v2.3.0-cn DMG](https://github.com/YiIimini/Atoll/releases/tag/v2.3.0-cn) | 基于原版增强，详见下方区别 |

### 中文优化版 vs 原版

| 项目 | 原版 | 中文优化版 |
|---|---|---|
| 界面语言 | 英文 | 中文（权限提示 + 设置 UI） |
| AI 供应商 | 仅 Gemini | **13 家**：Gemini / OpenAI / Claude / Groq / DeepSeek / OpenRouter / 本地 Ollama / 通义千问 / 月之暗面 / 智谱 GLM / 百川 / 零一万物 / Minimax |
| AI 设置 UI | 仅 Gemini API Key | 完整供应商切换、模型选择、Thinking Mode、独立 API Key 管理 |
| 专注模式 | 固定监控模式 | 可选 withDevTools / withoutDevTools |
| 设置完整性 | 部分设置键无 UI 覆盖 | 全部 180+ Defaults Keys 验收补齐 |
| ReadMe 文档 | 英文 | 中文 |

## 安装
1) 从上方链接下载对应版本的 DMG。
2) 打开 DMG，将 Atoll 拖入 Applications 文件夹。
3) 首次启动需在 **系统设置 → 隐私与安全性** 中允许运行（未签名版本）。
4) 启动后按提示授予所需权限。

## 亮点功能
- 支持 Apple Music、Spotify、Amazon Music 和 YouTube Music 的媒体控制，带内嵌预览。
- 实时活动：媒体播放、专注模式、屏幕录制、隐私指示器、下载（Beta）以及电池/充电状态。
- 锁屏小组件：媒体、计时器、充电、蓝牙设备、天气、日历和提醒事项。
- **屏幕助手（Screen Assistant）** — AI 驱动的对话与文件分析（`Cmd+Shift+A`）。支持 **13 家供应商**：Gemini、OpenAI GPT、Claude、Groq、DeepSeek、OpenRouter、本地模型（Ollama）以及 6 家国产大模型：通义千问、月之暗面（Kimi）、智谱 GLM、百川、零一万物、Minimax。在 设置 → Screen Assistant 中配置 API Key、选择模型、切换 Thinking 推理模式。
- 轻量级系统监控：CPU、GPU、内存、网络和磁盘使用。
- LLM 用量追踪：Claude / Codex / Cursor + 8 家国产模型（DeepSeek / 通义千问 / 月之暗面 / 智谱 GLM / 百川 / 零一万物 / Minimax / 讯飞星火），带配额监控。
- 生产力工具：计时器、剪贴板历史、取色器、日历预览。
- 布局、动画、悬停行为和快捷键自由定制。

## 更多特性
- 手势控制：双指上下滑动打开/关闭刘海，水平滑动切换曲目。
- 视差悬停交互，平滑过渡动画。
- 锁屏面板与小组件的外观和位置控制。
- Caps Lock 指示灯，支持多种颜色模式。
- 摄像头和麦克风隐私指示器（基于 CoreAudio / CoreMediaIO 事件驱动）。
- 内置终端（Guake 风格下拉），支持自定义 Shell、字体、颜色、光标和鼠标上报。
- Shelf 快捷文件架：拖放存取、LocalSend 设备间分享。
- 动态镜面（摄像头）嵌入刘海，支持圆形/方形。
- 自定义空闲动画与 Lottie 音乐可视化。

<p align="center">
  <img src="https://i.postimg.cc/HkLGn6yH/846F86A4_A2F9_4CD6_BC84_1D720D377728_1_201_a.jpg" alt="Atoll preview" width="920">
</p>

## 系统要求
- macOS 14.0 及以上（推荐 macOS 15+）。
- 带刘海的 MacBook（14/16 英寸 MBP，Apple 芯片全系列）。
- 从源码构建需 Xcode 15+。
- 所需权限：辅助功能、摄像头、日历、屏幕录制、音乐。

## 快速上手
- 鼠标悬停刘海附近即可展开，点击进入控制面板。
- 使用标签页切换媒体、状态监控、计时器、剪贴板等功能。
- 在设置中调整布局、外观和快捷键。
- 从终端添加文件到 Shelf：`open -a Atoll /path/to/file`。
- 按 `Cmd+Shift+A` 启动屏幕助手，与 AI 对话、分析文件或录制语音。

## 设置
Atoll 设置窗口分为 7 组、21 个标签页：

**核心** — 通用（启动、显示器、手势、刘海高度）和外观（玻璃材质、刘海宽度、可视化、镜面、空闲动画、应用图标）。

**媒体与显示** — 媒体（音乐来源、Spotify 授权、控制布局、歌词、实时画布）、实时活动（录制、专注模式、Caps Lock、隐私指示器、提醒事项）、锁屏（小组件：媒体、天气、计时器、日历；玻璃样式、位置、偏移量）和设备（蓝牙 HUD、电池指示器、AirPods 降噪模式）。

**系统** — 控制（灵动岛 HUD、自定义 OSD、竖条、圆形；进度条样式、音量/亮度步长、DDC 集成）和电池（充电/低电量/满电 HUD 通知与阈值）。

**生产力** — 计时器（预设、进度样式、镜像系统计时器、锁屏小组件）、日历（第三方应用集成、事件显示）和备忘录（Apple Notes 同步、置顶、搜索、颜色筛选）。

**实用工具** — 剪贴板管理器、屏幕助手（13 家 AI 供应商含 6 家国产大模型、模型选择、推理模式）、取色器（历史记录、格式）、Shelf（快速分享、LocalSend、拖放行为）、下载（Safari 监听、指示器样式）和快捷键（全局键盘快捷键）。

**开发者** — 系统状态（CPU/GPU/内存/网络/磁盘监控、LLM 用量追踪[Claude/Codex/Cursor + 8 家国产模型]与配额显示）和终端（Shell 路径、字体、颜色、光标、回滚行数、鼠标上报）。

**集成** — 扩展（第三方实时活动、锁屏小组件、刘海体验、权限管理）。

## 手势控制
- 关闭悬停打开时，双指向下滑动打开刘海；双指向上滑动关闭。
- 在 **设置 → 通用 → 手势控制** 中启用水平媒体手势，将音乐面板变成触控板，支持上一曲/下一曲或 ±10 秒跳转。
- 手势跳过行为（切歌 vs ±10s）与按钮配置独立设置，手势快进时按钮切歌——反之亦然。
- 水平滑动触发与点击操作一致的触觉反馈和按钮动画。

## 常见问题
- 授予辅助功能或屏幕录制权限后，退出并重新启动应用。
- 指标为空时，在 设置 → Stats 中开启对应监控项。
- 媒体无响应：确认播放器正在运行且已授予音乐权限。

## 致谢

本仓库 Fork 自 [Ebullioscopic/Atoll](https://github.com/Ebullioscopic/Atoll)，原作者 **Hariharan Mudaliar**，基于其杰出工作在 GPL v3 许可下进行二次开发。

同时也感谢以下开源项目的贡献与启发：
[Boring.Notch](https://github.com/TheBoredTeam/boring.notch) · [Alcove](https://tryalcove.com) · [Stats](https://github.com/exelban/stats) · [Open Meteo](https://open-meteo.com) · [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) · [rtaudio](https://github.com/ZephyrCodesStuff/rtaudio) · [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) · [DynamicNotch](https://github.com/jackson-storm/DynamicNotch) · [OpenUsage](https://github.com/robinebers/openusage) · [OpenRouter](https://openrouter.ai)

## 许可证
Atoll 基于 GPL v3 许可证发布。完整条款见 [LICENSE](LICENSE)。
