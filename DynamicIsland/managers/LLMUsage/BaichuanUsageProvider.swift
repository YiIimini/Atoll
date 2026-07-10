import Foundation

/// Tracks 百川 API usage via Atoll's Screen Assistant call log.
struct BaichuanUsageProvider: UsageProvider {
    let id: ProviderID = .baichuan
    let logDir: URL

    init(logDir: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("DynamicIsland/llm-usage")) {
        self.logDir = logDir
    }

    func fetchSnapshot(now: Date) async throws -> UsageSnapshot {
        guard FileManager.default.fileExists(atPath: logDir.path) else {
            throw UsageError.notFound("百川 用量日志尚未生成 — 请在屏幕助手中使用后重试")
        }
        let files = jsonlFiles(under: logDir).filter { $0.lastPathComponent.contains("baichuan") }
        guard !files.isEmpty else {
            throw UsageError.notFound("未找到 百川 用量记录")
        }
        return JSONLUsageParser.aggregate(files: files, now: now)
    }

    private func jsonlFiles(under dir: URL) -> [URL] {
        guard let en = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil) else { return [] }
        return en.compactMap { $0 as? URL }.filter { $0.pathExtension == "jsonl" }
    }
}
