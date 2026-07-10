import AppKit
import Foundation

// MARK: - 系统命令类型

enum SystemCommand: String, CaseIterable, Identifiable {
    case cleanCache    = "清理缓存"
    case emptyTrash    = "清空废纸篓"
    case lockScreen    = "锁屏"
    case sleep         = "休眠"
    case darkMode      = "切换暗色模式"
    case lightMode     = "切换亮色模式"
    case screenshot    = "截屏"
    case killProcess   = "结束进程"
    case systemInfo    = "系统信息"
    case openApp       = "打开应用"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .cleanCache:  return "清理系统缓存垃圾"
        case .emptyTrash:  return "清空废纸篓"
        case .lockScreen:  return "锁定屏幕"
        case .sleep:       return "让 Mac 进入休眠"
        case .darkMode:    return "切换到暗色模式"
        case .lightMode:   return "切换到亮色模式"
        case .screenshot:  return "截取全屏截图"
        case .killProcess: return "结束指定进程"
        case .systemInfo:  return "查看系统信息（CPU/内存/磁盘）"
        case .openApp:     return "打开应用程序"
        }
    }

    var icon: String {
        switch self {
        case .cleanCache:  return "wand.and.stars"
        case .emptyTrash:  return "trash.slash"
        case .lockScreen:  return "lock.fill"
        case .sleep:       return "moon.zzz.fill"
        case .darkMode:    return "moon.fill"
        case .lightMode:   return "sun.max.fill"
        case .screenshot:  return "camera.viewfinder"
        case .killProcess: return "xmark.circle"
        case .systemInfo:  return "chart.bar.fill"
        case .openApp:     return "app.badge"
        }
    }
}

// MARK: - 命令匹配器

struct CommandMatcher {
    /// 尝试从用户消息中匹配系统命令，返回匹配到的命令和置信度
    static func match(_ message: String) -> (SystemCommand, String?)? {
        let msg = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 清理缓存
        if msg.contains("清理缓存") || msg.contains("清除缓存") || msg.contains("clean cache") {
            return (.cleanCache, nil)
        }
        // 清空废纸篓
        if msg.contains("清空废纸篓") || msg.contains("清倒废纸篓") || msg.contains("empty trash") {
            return (.emptyTrash, nil)
        }
        // 锁屏
        if msg.contains("锁屏") || msg.contains("锁定屏幕") || msg.contains("lock screen") {
            return (.lockScreen, nil)
        }
        // 休眠
        if msg.contains("休眠") || msg.contains("睡眠") || msg.contains("sleep") {
            return (.sleep, nil)
        }
        // 暗色模式
        if msg.contains("暗色") || msg.contains("深色") || msg.contains("dark mode") {
            return (.darkMode, nil)
        }
        // 亮色模式
        if msg.contains("亮色") || msg.contains("浅色") || msg.contains("light mode") {
            return (.lightMode, nil)
        }
        // 截屏
        if msg.contains("截屏") || msg.contains("截图") || msg.contains("screenshot") {
            return (.screenshot, nil)
        }
        // 系统信息
        if msg.contains("系统信息") || msg.contains("cpu") || msg.contains("内存") && msg.contains("使用") {
            return (.systemInfo, nil)
        }
        // 打开应用
        if msg.hasPrefix("打开") || msg.hasPrefix("启动") || msg.hasPrefix("open ") {
            let appName = msg
                .replacingOccurrences(of: "打开", with: "")
                .replacingOccurrences(of: "启动", with: "")
                .replacingOccurrences(of: "open ", with: "")
                .trimmingCharacters(in: .whitespaces)
            guard !appName.isEmpty else { return nil }
            return (.openApp, appName)
        }
        // 结束进程
        if (msg.contains("结束") || msg.contains("杀掉") || msg.contains("kill")) && msg.contains("进程") {
            let procName = msg
                .replacingOccurrences(of: "结束进程", with: "")
                .replacingOccurrences(of: "杀掉进程", with: "")
                .replacingOccurrences(of: "kill", with: "")
                .trimmingCharacters(in: .whitespaces)
            return (.killProcess, procName.isEmpty ? nil : procName)
        }

        return nil
    }
}

// MARK: - 命令执行器

@MainActor
final class SystemCommandExecutor: ObservableObject {
    static let shared = SystemCommandExecutor()

    @Published var pendingCommand: SystemCommand?
    @Published var pendingArg: String?
    @Published var showConfirmation = false

    private init() {}

    /// 执行系统命令
    func execute(_ cmd: SystemCommand, arg: String? = nil) -> String {
        switch cmd {
        case .cleanCache:
            return cleanCache()
        case .emptyTrash:
            return emptyTrash()
        case .lockScreen:
            return lockScreen()
        case .sleep:
            return sleepMac()
        case .darkMode:
            return setAppearance(true)
        case .lightMode:
            return setAppearance(false)
        case .screenshot:
            return takeScreenshot()
        case .systemInfo:
            return getSystemInfo()
        case .openApp:
            return openApp(named: arg)
        case .killProcess:
            return killProcess(named: arg)
        }
    }

    /// 请求用户确认后执行
    func requestConfirmation(cmd: SystemCommand, arg: String?, onConfirm: @escaping (String) -> Void) {
        pendingCommand = cmd
        pendingArg = arg
        showConfirmation = true
        // 实际执行在 UI 确认后调用
        _onConfirm = onConfirm
    }

    private var _onConfirm: ((String) -> Void)?

    func confirmExecution() {
        guard let cmd = pendingCommand else { return }
        let result = execute(cmd, arg: pendingArg)
        _onConfirm?(result)
        showConfirmation = false
        pendingCommand = nil
        pendingArg = nil
    }

    func cancelExecution() {
        showConfirmation = false
        pendingCommand = nil
        pendingArg = nil
    }

    // MARK: - 具体实现

    private func cleanCache() -> String {
        let paths = [
            NSString(string: "~/Library/Caches").expandingTildeInPath,
            NSString(string: "~/Library/Logs").expandingTildeInPath,
        ]
        var cleaned: UInt64 = 0
        for p in paths {
            cleaned += dirSize(p)
            try? FileManager.default.removeItem(atPath: p)
            try? FileManager.default.createDirectory(atPath: p, withIntermediateDirectories: true)
        }
        return "✅ 已清理缓存，释放约 \(ByteCountFormatter.string(fromByteCount: Int64(cleaned), countStyle: .file))"
    }

    private func emptyTrash() -> String {
        let trash = NSString(string: "~/.Trash").expandingTildeInPath
        let size = dirSize(trash)
        try? FileManager.default.removeItem(atPath: trash)
        return "✅ 已清空废纸篓，释放约 \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))"
    }

    private func lockScreen() -> String {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]
        task.launch()
        return "🔒 屏幕已锁定"
    }

    private func sleepMac() -> String {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["sleepnow"]
        task.launch()
        return "😴 Mac 进入休眠"
    }

    private func setAppearance(_ dark: Bool) -> String {
        let script = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to \(dark)
            end tell
        end tell
        """
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.launch()
        task.waitUntilExit()
        return dark ? "🌙 已切换到暗色模式" : "☀️ 已切换到亮色模式"
    }

    private func takeScreenshot() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        let desktop = NSString(string: "~/Desktop/screenshot_\(Int(Date().timeIntervalSince1970))).png").expandingTildeInPath
        task.arguments = ["-x", desktop]
        task.launch()
        task.waitUntilExit()
        return "📸 截图已保存到桌面: screenshot_*.png"
    }

    private func getSystemInfo() -> String {
        var info = "📊 **系统状态**\n\n"

        // CPU
        let cpu = runShell("top -l 1 -n 0 | grep 'CPU usage' | awk '{print $3, $5, $7}'")
        info += "• CPU: \(cpu)\n"

        // 内存
        let mem = runShell("vm_stat | awk '/Pages active/ {a=$3} /Pages wired/ {w=$4} /Pages occupied/ {o=$3} END {printf \"%.1f GB used\\n\", (a+w)*4096/1073741824}'")
        info += "• 内存: \(mem)\n"

        // 磁盘
        let disk = runShell("df -h / | tail -1 | awk '{print \"已用 \"$3\" / 共 \"$2\" (\"$5\")\"}'")
        info += "• 磁盘: \(disk)\n"

        // 运行时间
        let uptime = runShell("uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}'")
        info += "• 运行时间: \(uptime)"

        return info
    }

    private func openApp(named name: String?) -> String {
        guard let name else { return "❌ 请指定应用名称" }
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", name]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus == 0 ? "✅ 已打开 \(name)" : "❌ 未找到应用: \(name)"
    }

    private func killProcess(named name: String?) -> String {
        guard let name else { return "❌ 请指定进程名称" }
        let result = runShell("pkill -f '\(name)' 2>&1")
        return result.isEmpty ? "✅ 已结束进程: \(name)" : "❌ 未找到进程: \(name)"
    }

    private func dirSize(_ path: String) -> UInt64 {
        let fm = FileManager.default
        guard fm.fileExists(atPath: path),
              let en = fm.enumerator(at: URL(fileURLWithPath: path),
                                      includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: UInt64 = 0
        for case let url as URL in en {
            total += UInt64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }

    private func runShell(_ cmd: String) -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", cmd]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
