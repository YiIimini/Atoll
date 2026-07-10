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
        let output = runShell("ps -eo pid,pcpu,rss,user,comm -r | head -60")
        let lines = output.components(separatedBy: "\n").dropFirst()
        var procs: [ProcessEntry] = []

        for line in lines {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 5,
                  let pid = Int32(parts[0]),
                  let cpu = Double(parts[1]),
                  let mem = UInt64(parts[2]) else { continue }
            let memBytes = mem * 1024
            let user = String(parts[3])
            let name = parts.dropFirst(4).joined(separator: " ")

            // Filter out system processes
            guard pid > 100, !name.hasPrefix("kernel"), name != "ps" else { continue }
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
