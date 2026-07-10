<p align="center">
  <img src=".github/assets/atoll-logo.png" alt="Atoll logo" width="120">
</p>
<h1 align="center">Atoll — macOS 灵动岛</h1>
<p align="center">
<a href="https://trendshift.io/repositories/15291" target="_blank"><img src="https://trendshift.io/api/badge/repositories/15291" alt="Ebullioscopic%2FAtoll | Trendshift" style="width: 250px; height: 55px;" width="250" height="55"/></a>
</p>
<p align="center">
  <a href="https://github.com/Ebullioscopic/Atoll/stargazers">
    <img src="https://img.shields.io/github/stars/Ebullioscopic/Atoll?style=social" alt="GitHub stars"/>
  </a>
  <a href="https://github.com/Ebullioscopic/Atoll/network/members">
    <img src="https://img.shields.io/github/forks/Ebullioscopic/Atoll?style=social" alt="GitHub forks"/>
  </a>
  <a href="https://github.com/Ebullioscopic/Atoll/releases">
    <img src="https://img.shields.io/github/downloads/Ebullioscopic/Atoll/total?label=Downloads" alt="GitHub downloads"/>
  </a>
  <a href="https://discord.gg/PaqFkRTDF8">
    <img src="https://dcbadge.limes.pink/api/server/https://discord.gg/PaqFkRTDF8?style=flat" alt="Discord server"/>
  </a>
</p>

<p align="center">
  <a href="https://github.com/sponsors/Ebullioscopic">
    <img src="https://img.shields.io/badge/Sponsor-Ebullioscopic-ff69b4?style=for-the-badge&logo=github" alt="Sponsor Ebullioscopic"/>
  </a>
  <a href="https://github.com/Ebullioscopic/Atoll/releases/latest">
    <img src="https://img.shields.io/badge/Download-Atoll%20for%20macOS-0A84FF?style=for-the-badge&logo=apple" alt="Download Atoll for macOS"/>
  </a>
  <a href="https://www.buymeacoffee.com/kryoscopic">
    <img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-kryoscopic-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=000000" alt="Buy Me a Coffee for kryoscopic"/>
  </a>
</p>

<p align="center">
  <a href="https://discord.gg/PaqFkRTDF8">加入 Discord 社区</a>
</p>

Atoll 将 MacBook 的刘海变成媒体控制、系统监控和快捷工具的集中操作台。未使用时安静隐藏，需要时展开为流畅的原生 SwiftUI 动画界面。

<p align="center">
  <img src="https://i.postimg.cc/t49mW5yN/Screenshot-2026-03-02-at-6-00-22-PM.png" alt="Atoll lock screen" width="920">
</p>

## 亮点功能
- 支持 Apple Music、Spotify、Amazon Music 和 YouTube Music 的媒体控制，带内嵌预览。
- 实时活动：媒体播放、专注模式、屏幕录制、隐私指示器、下载（Beta）以及电池/充电状态。
- 锁屏小组件：媒体、计时器、充电、蓝牙设备、天气、日历和提醒事项。
- **屏幕助手（Screen Assistant）** — AI 驱动的对话与文件分析（`Cmd+Shift+A`）。支持 **7 家供应商**：Gemini、OpenAI GPT、Claude、Groq、DeepSeek、OpenRouter 以及本地模型（Ollama）。在 设置 → Screen Assistant 中配置 API Key、选择模型、切换 Thinking 推理模式。
- 轻量级系统监控：CPU、GPU、内存、网络和磁盘使用。
- LLM 用量追踪（Claude / Codex / Cursor），带配额监控。
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

## 安装
1) 在 [此处](https://github.com/Ebullioscopic/Atoll/releases/latest) 下载最新 DMG。
2) 打开 DMG，将 Atoll 拖入 Applications 文件夹。
3) 启动 Atoll 并按提示授予所需权限。

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

**实用工具** — 剪贴板管理器、屏幕助手（7 家 AI 供应商、模型选择、推理模式）、取色器（历史记录、格式）、Shelf（快速分享、LocalSend、拖放行为）、下载（Safari 监听、指示器样式）和快捷键（全局键盘快捷键）。

**开发者** — 系统状态（CPU/GPU/内存/网络/磁盘监控、Claude/Codex/Cursor LLM 用量追踪与配额显示）和终端（Shell 路径、字体、颜色、光标、回滚行数、鼠标上报）。

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

## 许可证
Atoll 基于 GPL v3 许可证发布。完整条款见 [LICENSE](LICENSE)。

## 致谢

Atoll 建立在多个开源项目之上，并受创新 macOS 应用的启发：

- [**Boring.Notch**](https://github.com/TheBoredTeam/boring.notch) — 提供了初始的媒体播放器集成、AirDrop 界面、文件 Dock 和日历事件显示的基础代码。主要架构模式和刘海交互模型均源自此项目。

- [**Alcove**](https://tryalcove.com) — 极简模式界面设计的主要灵感来源，锁屏小组件集成概念启发了 Atoll 的紧凑布局策略。

- [**Stats**](https://github.com/exelban/stats) — CPU 温度监控（SMC 访问）、频率采样（IOReport）和逐核 CPU 利用率的实现参考。系统指标采集架构源于 Stats 的 reader 设计。

- [**Open Meteo**](https://open-meteo.com) — 锁屏小组件的天气 API

- [**SkyLightWindow**](https://github.com/Lakr233/SkyLightWindow) — 锁屏小组件的窗口渲染

- [**rtaudio**](https://github.com/ZephyrCodesStuff/rtaudio) — C++ 实时音乐可视化，经适配集成

- [**SwiftTerm**](https://github.com/migueldeicaza/SwiftTerm) — 标准模式下的终端标签页实现

- [**DynamicNotch**](https://github.com/jackson-storm/DynamicNotch) — 感谢 DynamicNotch 授权使用其电池 HUD

- Wick — 感谢 Nate 允许复刻 iOS 风格的锁屏计时器设计

- [**OpenUsage**](https://github.com/robinebers/openusage) — LLM 用量追踪功能

- [**OpenRouter**](https://openrouter.ai) — 模型定价自动获取 API

## 贡献者

<a href="https://github.com/Ebullioscopic/Atoll/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Ebullioscopic/Atoll" />
</a>

## Star 历史

[![Star History Chart](https://api.star-history.com/svg?repos=Ebullioscopic/Atoll&type=timeline&legend=top-left)](https://www.star-history.com/#Ebullioscopic/Atoll&type=timeline&legend=top-left)

## 更新已有克隆
如果你之前克隆了 DynamicIsland，更新远程地址以跟踪 Atoll 仓库：

```bash
git remote set-url origin https://github.com/Ebullioscopic/Atoll.git
```

由衷感谢 [TheBoredTeam](https://github.com/TheBoredTeam) 的支持，没有 Boring.Notch 就没有 Atoll。

---

<p align="center">
  <img src=".github/assets/iosdevcentre.jpeg" alt="iOS Development Centre exterior" width="420">
  <br>
  <sub>Backed by</sub>
  <br>
  <strong>iOS Development Centre</strong>
  <br>
  Powered by Apple and Infosys
  <br>
  SRM Institute of Science and Technology, Chennai, India
</p>

<p align="center">
  <a href="https://buymeacoffee.com/kryoscopic">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="200" />
  </a>
</p>

<p align="center">
  您的支持将帮助资助儿童软件开发教育。
</p>
