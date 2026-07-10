import Foundation
import AppKit

// MARK: - Data Models

struct CacheEntry: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let name: String
    let sizeBytes: UInt64
    let category: CacheCategory
    var isSelected: Bool = true

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
    }

    enum CacheCategory: String, CaseIterable {
        case user = "用户缓存"
        case system = "系统缓存"
        case xcode = "Xcode"
        case logs = "日志文件"
        case trash = "废纸篓"
    }
}

struct ProcessEntry: Identifiable, Hashable {
    let id = UUID()
    let pid: Int32
    let name: String
    let cpuPercent: Double
    let memoryBytes: UInt64
    let user: String

    var memoryFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryBytes), countStyle: .memory)
    }

    var cpuFormatted: String {
        String(format: "%.1f%%", cpuPercent)
    }

    /// 进程类型图标
    var categoryIcon: String {
        let lower = name.lowercased()
        if lower.contains("xcode") || lower.contains("swift") || lower.contains("clang") { return "hammer" }
        if lower.contains("safari") || lower.contains("chrome") || lower.contains("firefox") || lower.contains("edge") { return "safari" }
        if lower.contains("terminal") || lower.contains("iterm") || lower.contains("warp") { return "terminal" }
        if lower.contains("finder") { return "finder" }
        if lower.contains("music") || lower.contains("spotify") { return "music.note" }
        if lower.contains("code") || lower.contains("cursor") { return "chevron.left.forwardslash.chevron.right" }
        if lower.contains("docker") { return "shippingbox" }
        if lower.contains("node") || lower.contains("npm") { return "circle.hexagongrid" }
        if lower.contains("python") { return "snake" }
        if lower.contains("git") { return "arrow.triangle.branch" }
        return "app.dashed"
    }

    /// 人类可读的进程描述
    var displayDescription: String {
        let lower = name.lowercased()
        if lower.contains("safari") { return "Safari 浏览器" }
        if lower.contains("chrome") && lower.contains("helper") { return "Chrome 渲染器" }
        if lower.contains("chrome") { return "Chrome 浏览器" }
        if lower.contains("firefox") { return "Firefox 浏览器" }
        if lower.contains("xcode") && lower.contains("build") { return "Xcode 构建" }
        if lower.contains("xcode") { return "Xcode" }
        if lower.contains("swift") { return "Swift 编译" }
        if lower.contains("terminal") { return "终端" }
        if lower.contains("finder") { return "访达" }
        if lower.contains("spotify") { return "Spotify" }
        if lower.contains("music") && !lower.contains("itunes") { return "Apple Music" }
        if lower.contains("code") && lower.contains("cursor") { return "Cursor" }
        if lower.contains("code") && lower.contains("visual") { return "VS Code" }
        if lower.contains("docker") { return "Docker" }
        if lower.contains("node") { return "Node.js" }
        if lower.contains("python") { return "Python" }
        if lower.contains("git") { return "Git" }
        if lower.contains("wechat") || lower.contains("微信") { return "微信" }
        return name
    }
}

// MARK: - Manager

@MainActor
final class SystemCleanerManager: ObservableObject {
    static let shared = SystemCleanerManager()

    @Published var cacheEntries: [CacheEntry] = []
    @Published var processEntries: [ProcessEntry] = []
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var lastScanTime: Date?
    @Published var totalCacheSize: UInt64 = 0
    @Published var selectedCacheSize: UInt64 = 0

    private init() {}

    // MARK: - Cache Scanning

    func scanCaches() async {
        isScanning = true
        defer { isScanning = false; lastScanTime = Date() }

        var entries: [CacheEntry] = []

        await withTaskGroup(of: [CacheEntry].self) { group in
            // 用户缓存
            group.addTask { await self.scanDirectory("~/Library/Caches", name: "用户应用缓存", category: .user) }
            // 系统缓存
            group.addTask { await self.scanDirectory("/Library/Caches", name: "系统缓存", category: .system) }
            // Xcode
            group.addTask { await self.scanXcodeDerivedData() }
            // 日志
            group.addTask { await self.scanLogs() }
            // 废纸篓
            group.addTask { await self.scanTrash() }

            for await result in group {
                entries.append(contentsOf: result)
            }
        }

        entries.sort { $0.sizeBytes > $1.sizeBytes }
        cacheEntries = entries
        recalcSizes()
    }

    private func scanDirectory(_ path: String, name: String, category: CacheEntry.CacheCategory) async -> [CacheEntry] {
        let expanded = NSString(string: path).expandingTildeInPath
        let size = directorySize(expanded)
        guard size > 0 else { return [] }
        return [CacheEntry(path: expanded, name: name, sizeBytes: size, category: category)]
    }

    private func scanXcodeDerivedData() async -> [CacheEntry] {
        let derivedData = NSString(string: "~/Library/Developer/Xcode/DerivedData").expandingTildeInPath
        let size = directorySize(derivedData)
        guard size > 0 else { return [] }

        // Also check iOS Device Support
        let deviceSupport = NSString(string: "~/Library/Developer/Xcode/iOS DeviceSupport").expandingTildeInPath
        let dsSize = directorySize(deviceSupport)

        // Archives
        let archives = NSString(string: "~/Library/Developer/Xcode/Archives").expandingTildeInPath
        let archSize = directorySize(archives)

        var entries: [CacheEntry] = [
            CacheEntry(path: derivedData, name: "Xcode DerivedData", sizeBytes: size, category: .xcode)
        ]
        if dsSize > 0 {
            entries.append(CacheEntry(path: deviceSupport, name: "iOS Device Support", sizeBytes: dsSize, category: .xcode))
        }
        if archSize > 0 {
            entries.append(CacheEntry(path: archives, name: "Xcode Archives", sizeBytes: archSize, category: .xcode))
        }
        return entries
    }

    private func scanLogs() async -> [CacheEntry] {
        let userLogs = NSString(string: "~/Library/Logs").expandingTildeInPath
        let size = directorySize(userLogs)
        guard size > 0 else { return [] }
        return [CacheEntry(path: userLogs, name: "用户日志", sizeBytes: size, category: .logs)]
    }

    private func scanTrash() async -> [CacheEntry] {
        let trash = NSString(string: "~/.Trash").expandingTildeInPath
        let size = directorySize(trash)
        guard size > 0 else { return [] }
        return [CacheEntry(path: trash, name: "废纸篓", sizeBytes: size, category: .trash)]
    }

    private func directorySize(_ path: String) -> UInt64 {
        let fm = FileManager.default
        guard fm.fileExists(atPath: path) else { return 0 }
        guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: path),
                                              includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey],
                                              options: [.skipsHiddenFiles]) else { return 0 }
        var total: UInt64 = 0
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey]) else { continue }
            let size = UInt64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            total += size
            if total > 50_000_000_000 { break } // Cap at 50GB to avoid hanging
        }
        return total
    }

    // MARK: - Clean

    func cleanSelected() async {
        let selected = cacheEntries.filter { $0.isSelected }
        guard !selected.isEmpty else { return }

        isCleaning = true
        defer { isCleaning = false }

        for entry in selected {
            do {
                try FileManager.default.removeItem(atPath: entry.path)
                print("🧹 Cleaned: \(entry.name) (\(entry.sizeFormatted))")
            } catch {
                print("⚠️ Failed to clean \(entry.name): \(error.localizedDescription)")
            }
        }

        // Rescan after cleaning
        await scanCaches()
    }

    func toggleSelection(for entry: CacheEntry) {
        guard let idx = cacheEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        cacheEntries[idx].isSelected.toggle()
        recalcSizes()
    }

    private func recalcSizes() {
        totalCacheSize = cacheEntries.reduce(0) { $0 + $1.sizeBytes }
        selectedCacheSize = cacheEntries.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
    }

    // MARK: - Process Scanning

    func scanProcesses() async {
        // ps: pid, cpu%, rss(KB), user, comm (进程名不含路径)
        let output = runShell("ps -eo pid,pcpu,rss,user,comm -r 2>/dev/null | head -80")
        let lines = output.components(separatedBy: "\n").dropFirst()
        var procs: [ProcessEntry] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // 按空格拆分，前4列固定，剩余全算作进程名
            let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 5,
                  let pid = Int32(parts[0]),
                  let cpu = Double(parts[1]),
                  let mem = UInt64(parts[2]) else { continue }
            let memBytes = mem * 1024
            let user = String(parts[3])
            var name = parts.dropFirst(4).joined(separator: " ")

            // 如果进程名是路径，只取最后一段
            if name.contains("/") {
                name = (name as NSString).lastPathComponent
            }

            // 过滤内核和ps本身
            guard pid > 100, name != "ps", !name.hasPrefix("kernel_task") else { continue }
            procs.append(ProcessEntry(pid: pid, name: name, cpuPercent: cpu, memoryBytes: memBytes, user: user))
        }

        processEntries = procs
    }

    func killProcess(_ entry: ProcessEntry) {
        let result = runShell("kill \(entry.pid)")
        print("🔪 Kill \(entry.name) (PID \(entry.pid)): \(result.isEmpty ? "OK" : result)")
        Task { await scanProcesses() }
    }

    // MARK: - Helpers

    private func runShell(_ cmd: String) -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", cmd]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
