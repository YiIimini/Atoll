import Foundation

/// Tracks 月之暗面 (Moonshot/Kimi) API usage via Atoll's Screen Assistant call log.
struct MoonshotUsageProvider: UsageProvider {
    let id: ProviderID = .moonshot
    let logDir: URL

    init(logDir: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("DynamicIsland/llm-usage")) {
        self.logDir = logDir
    }

    func fetchSnapshot(now: Date) async throws -> UsageSnapshot {
        guard FileManager.default.fileExists(atPath: logDir.path) else {
            throw UsageError.notFound("Moonshot 用量日志尚未生成 — 请通过 API 调用后重试")
        }
        let files = jsonlFiles(under: logDir).filter { $0.lastPathComponent.contains("moonshot") }
        guard !files.isEmpty else {
            throw UsageError.notFound("未找到 Moonshot 用量记录")
        }
        return JSONLUsageParser.aggregate(files: files, now: now)
    }

    private func jsonlFiles(under dir: URL) -> [URL] {
        guard let en = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil) else { return [] }
        return en.compactMap { $0 as? URL }.filter { $0.pathExtension == "jsonl" }
    }
}
