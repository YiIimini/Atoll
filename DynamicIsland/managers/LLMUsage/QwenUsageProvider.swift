import Foundation

/// Tracks 通义千问 (DashScope) API usage via Atoll's Screen Assistant call log.
struct QwenUsageProvider: UsageProvider {
    let id: ProviderID = .qwen
    let logDir: URL

    init(logDir: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("DynamicIsland/llm-usage")) {
        self.logDir = logDir
    }

    func fetchSnapshot(now: Date) async throws -> UsageSnapshot {
        guard FileManager.default.fileExists(atPath: logDir.path) else {
            throw UsageError.notFound("通义千问用量日志尚未生成 — 请通过 API 调用后重试")
        }
        let files = jsonlFiles(under: logDir).filter { $0.lastPathComponent.contains("qwen") }
        guard !files.isEmpty else {
            throw UsageError.notFound("未找到通义千问用量记录")
        }
        return JSONLUsageParser.aggregate(files: files, now: now)
    }

    private func jsonlFiles(under dir: URL) -> [URL] {
        guard let en = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil) else { return [] }
        return en.compactMap { $0 as? URL }.filter { $0.pathExtension == "jsonl" }
    }
}
