import AppKit
import Combine
import Defaults
import SwiftUI

struct StatsSettings: View {
    @ObservedObject var statsManager = StatsManager.shared
    @Default(.enableStatsFeature) var enableStatsFeature
    @Default(.enableLLMUsageFeature) var enableLLMUsageFeature
    @Default(.statsStopWhenNotchCloses) var statsStopWhenNotchCloses
    @Default(.statsUpdateInterval) var statsUpdateInterval
    @Default(.showCpuGraph) var showCpuGraph
    @Default(.showMemoryGraph) var showMemoryGraph
    @Default(.showGpuGraph) var showGpuGraph
    @Default(.showNetworkGraph) var showNetworkGraph
    @Default(.showDiskGraph) var showDiskGraph
    @Default(.cpuTemperatureUnit) var cpuTemperatureUnit

    // LLM provider toggles
    @Default(.enableClaudeProvider) var enableClaudeProvider
    @Default(.enableCodexProvider) var enableCodexProvider
    @Default(.enableCursorProvider) var enableCursorProvider
    @Default(.enableDeepseekProvider) var enableDeepseekProvider
    @Default(.enableQwenProvider) var enableQwenProvider
    @Default(.enableMoonshotProvider) var enableMoonshotProvider

    private func highlightID(_ title: String) -> String {
        SettingsTab.stats.highlightID(for: title)
    }

    var enabledGraphsCount: Int {
        [showCpuGraph, showMemoryGraph, showGpuGraph, showNetworkGraph, showDiskGraph].filter { $0 }.count
    }

    private var formattedUpdateInterval: String {
        let seconds = Int(statsUpdateInterval.rounded())
        if seconds >= 60 {
            return "60 秒（1 分钟）"
        } else if seconds == 1 {
            return "1 秒"
        } else {
            return "\(seconds) 秒"
        }
    }

    private var shouldShowBatteryWarning: Bool {
        !statsStopWhenNotchCloses && statsUpdateInterval <= 5
    }

    var body: some View {
        Form {
            // MARK: - 总开关
            Section {
                Defaults.Toggle(key: .enableStatsFeature) {
                    Text("启用系统状态监控")
                }
                .settingsHighlight(id: highlightID("启用系统状态监控"))
                .onChange(of: enableStatsFeature) { _, newValue in
                    if !newValue { statsManager.stopMonitoring() }
                }

                Defaults.Toggle(key: .enableLLMUsageFeature) {
                    Text("启用 LLM 用量监测")
                }
                .settingsHighlight(id: highlightID("启用 LLM 用量监测"))
            } header: {
                Text("通用")
            } footer: {
                Text("开启后，Stats 标签页将显示实时系统性能图表。LLM 用量监测会追踪已配置 AI 供应商的 Token 消耗和费用。")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            // MARK: - LLM 供应商选择
            if enableLLMUsageFeature {
                Section {
                    Defaults.Toggle(key: .enableClaudeProvider) {
                        Text("Claude（Anthropic）")
                    }
                    .settingsHighlight(id: highlightID("Claude 供应商"))

                    Defaults.Toggle(key: .enableCodexProvider) {
                        Text("Codex（OpenAI）")
                    }
                    .settingsHighlight(id: highlightID("Codex 供应商"))

                    Defaults.Toggle(key: .enableCursorProvider) {
                        Text("Cursor")
                    }
                    .settingsHighlight(id: highlightID("Cursor 供应商"))

                    Defaults.Toggle(key: .enableDeepseekProvider) {
                        HStack(spacing: 4) {
                            Text("DeepSeek（深度求索）")
                            customBadge(text: "国产")
                        }
                    }
                    .settingsHighlight(id: highlightID("DeepSeek 供应商"))

                    Defaults.Toggle(key: .enableQwenProvider) {
                        HStack(spacing: 4) {
                            Text("通义千问（阿里云）")
                            customBadge(text: "国产")
                        }
                    }
                    .settingsHighlight(id: highlightID("通义千问 供应商"))

                    Defaults.Toggle(key: .enableMoonshotProvider) {
                        HStack(spacing: 4) {
                            Text("Moonshot（月之暗面）")
                            customBadge(text: "国产")
                        }
                    }
                    .settingsHighlight(id: highlightID("Moonshot 供应商"))
                } header: {
                    Text("LLM 供应商")
                } footer: {
                    Text("选择需要监测的 AI 供应商。国产模型通过屏幕助手的 API 调用日志进行追踪，需先在 Screen Assistant 中配置对应 API Key 并使用后方可生成用量数据。")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            // MARK: - 监控行为
            if enableStatsFeature {
                Section {
                    Defaults.Toggle(key: .statsStopWhenNotchCloses) {
                        Text("关闭灵动岛后停止监测")
                    }
                    .settingsHighlight(id: highlightID("关闭灵动岛后停止监测"))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("刷新间隔")
                            Spacer()
                            Text(formattedUpdateInterval)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $statsUpdateInterval, in: 1...60, step: 1)
                        Text("控制监测激活时系统指标的刷新频率。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if shouldShowBatteryWarning {
                        Label("高频刷新且无超时限制可能增加耗电。", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.top, 4)
                    }
                } header: {
                    Text("监测行为")
                }
            }

            // MARK: - 图表可见性
            if enableStatsFeature {
                Section {
                    Defaults.Toggle(key: .showCpuGraph) {
                        Text("CPU 使用率")
                    }
                    .settingsHighlight(id: highlightID("CPU 使用率"))

                    if showCpuGraph {
                        Picker("温度单位", selection: $cpuTemperatureUnit) {
                            ForEach(LockScreenWeatherTemperatureUnit.allCases) { unit in
                                Text(unit.localizedName).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .settingsHighlight(id: highlightID("温度单位"))
                    }

                    Defaults.Toggle(key: .showMemoryGraph) {
                        Text("内存使用")
                    }
                    .settingsHighlight(id: highlightID("内存使用"))

                    Defaults.Toggle(key: .showGpuGraph) {
                        Text("GPU 使用率")
                    }
                    .settingsHighlight(id: highlightID("GPU 使用率"))

                    Defaults.Toggle(key: .showNetworkGraph) {
                        Text("网络活动")
                    }
                    .settingsHighlight(id: highlightID("网络活动"))

                    Defaults.Toggle(key: .showDiskGraph) {
                        Text("磁盘读写")
                    }
                    .settingsHighlight(id: highlightID("磁盘读写"))
                } header: {
                    Text("图表可见性")
                } footer: {
                    if enabledGraphsCount >= 4 {
                        Text("已启用 \(enabledGraphsCount) 个图表，灵动岛将横向扩展以容纳全部图表。")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        Text("每个图表可独立开关。网络活动显示上传/下载速率，磁盘读写显示读/写速率。")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }

            // MARK: - 实时数据
            if enableStatsFeature && statsManager.isMonitoring {
                Section {
                    HStack {
                        Text("监测状态")
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("运行中")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if showCpuGraph {
                        HStack {
                            Text("CPU 使用率")
                            Spacer()
                            Text(statsManager.cpuUsageString)
                                .foregroundStyle(.secondary)
                        }
                        // 风扇转速（首个有数据的 GPU）
                        if let firstGPU = statsManager.gpuDevices.first(where: { $0.fanSpeed != nil }) {
                            HStack {
                                Text("风扇转速")
                                Spacer()
                                Text("\(firstGPU.fanSpeed!)%")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if showMemoryGraph {
                        HStack {
                            Text("内存使用")
                            Spacer()
                            Text(statsManager.memoryUsageString)
                                .foregroundStyle(.secondary)
                        }
                        if let pressure = statsManager.memoryPressure?.level {
                            HStack {
                                Text("内存压力")
                                Spacer()
                                Text(pressure.rawValue)
                                    .foregroundStyle(pressure == .normal ? .green : pressure == .warning ? .orange : .red)
                            }
                        }
                    }

                    if showGpuGraph {
                        HStack {
                            Text("GPU 使用率")
                            Spacer()
                            Text(statsManager.gpuUsageString)
                                .foregroundStyle(.secondary)
                        }
                        // 逐 GPU 温度
                        ForEach(statsManager.gpuDevices) { gpu in
                            HStack {
                                Text("\(gpu.formattedVendorModel) 温度")
                                Spacer()
                                Text(gpu.temperatureText)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if showNetworkGraph {
                        HStack {
                            Text("下载速率")
                            Spacer()
                            Text(String(format: "%.1f MB/s", statsManager.networkDownload))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("上传速率")
                            Spacer()
                            Text(String(format: "%.1f MB/s", statsManager.networkUpload))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if showDiskGraph {
                        HStack {
                            Text("磁盘读取")
                            Spacer()
                            Text(String(format: "%.1f MB/s", statsManager.diskRead))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("磁盘写入")
                            Spacer()
                            Text(String(format: "%.1f MB/s", statsManager.diskWrite))
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Text("上次更新")
                        Spacer()
                        Text(statsManager.lastUpdated, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("实时数据")
                }
            }

            // MARK: - 控制按钮
            if enableStatsFeature {
                Section {
                    HStack {
                        Button(statsManager.isMonitoring ? "停止监测" : "开始监测") {
                            if statsManager.isMonitoring {
                                statsManager.stopMonitoring()
                            } else {
                                statsManager.startMonitoring()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(statsManager.isMonitoring ? .red : .blue)

                        Spacer()

                        Button("清除数据") {
                            statsManager.clearHistory()
                        }
                        .buttonStyle(.bordered)
                        .disabled(statsManager.isMonitoring)
                    }
                } header: {
                    Text("操作")
                }
            }
        }
        .navigationTitle("系统状态")
    }
}
