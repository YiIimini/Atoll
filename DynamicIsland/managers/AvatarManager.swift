import AppKit
import AVFoundation

// MARK: - 虚拟人管理器

@MainActor
final class AvatarManager: ObservableObject {
    static let shared = AvatarManager()

    @Published var isVisible: Bool = false

    private var avatarWindow: Live2DAvatarWindow?
    private var expressionTimer: Timer?
    private var lipSyncTimer: Timer?
    private var currentExpression: String = "neutral"

    // 表情列表
    enum Live2DExpression: String, CaseIterable {
        case neutral   = "neutral"
        case happy     = "happy"
        case sad       = "sad"
        case angry     = "angry"
        case surprised = "surprised"
        case thinking  = "thinking"
    }

    private init() {}

    // MARK: - 显示/隐藏

    func show() {
        guard avatarWindow == nil else { return }
        let window = Live2DAvatarWindow()
        window.onTap = { [weak self] in
            // 点击虚拟人 → 打开聊天
            ScreenAssistantPanelManager.shared.showScreenAssistantPanel()
        }
        window.orderFront(nil)
        avatarWindow = window
        isVisible = true
        startExpressionCycle()
        startLipSync()
    }

    func hide() {
        avatarWindow?.close()
        avatarWindow = nil
        isVisible = false
        stopExpressionCycle()
        stopLipSync()
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    // MARK: - 表情控制

    func setExpression(_ expr: Live2DExpression) {
        currentExpression = expr.rawValue
        avatarWindow?.sendToJS([
            "type": "expression",
            "name": expr.rawValue
        ])
    }

    /// 情感引擎 → 表情
    func setEmotion(_ emotion: String) {
        let expr: Live2DExpression
        switch emotion.lowercased() {
        case "happy", "joy":     expr = .happy
        case "sad", "sorrow":    expr = .sad
        case "angry", "mad":     expr = .angry
        case "surprised", "wow": expr = .surprised
        case "thinking", "hmm":  expr = .thinking
        default:                 expr = .neutral
        }
        setExpression(expr)
    }

    /// 闲时随机表情切换
    private func startExpressionCycle() {
        expressionTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                let random = Live2DExpression.allCases.randomElement() ?? .neutral
                self?.setExpression(random)
            }
        }
    }

    private func stopExpressionCycle() {
        expressionTimer?.invalidate()
        expressionTimer = nil
    }

    // MARK: - 口型同步

    private func startLipSync() {
        lipSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                let level = self?.audioLevel() ?? 0
                // 将音量映射到口型 0-1
                let mouthOpen = min(1.0, level * 3.0)
                self?.avatarWindow?.sendToJS([
                    "type": "mouthOpen",
                    "ratio": mouthOpen
                ])
            }
        }
    }

    private func stopLipSync() {
        lipSyncTimer?.invalidate()
        lipSyncTimer = nil
    }

    /// 获取当前系统音频输出音量（用于口型同步）
    private func audioLevel() -> Float {
        // 使用 VoiceConversationManager 的 isSpeaking 状态
        if VoiceConversationManager.shared.isSpeaking {
            return 0.8  // 正在说话时口型较大
        }
        if VoiceConversationManager.shared.isActive {
            return 0.15 // 对话活跃但没说话时微微动
        }
        return 0.0
    }

    // MARK: - 动作

    func playMotion(_ name: String) {
        avatarWindow?.sendToJS([
            "type": "motion",
            "name": name
        ])
    }


    /// 从 AI 回复文本中推断情感
    func emotionFromText(_ text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("哈哈") || lower.contains("开心") || lower.contains("great") || lower.contains("love") { return "happy" }
        if lower.contains("抱歉") || lower.contains("难过") || lower.contains("sorry") { return "sad" }
        if lower.contains("!") && text.count < 60 { return "surprised" }
        if lower.contains("嗯") || lower.contains("让我想想") || lower.contains("hmm") { return "thinking" }
        return "neutral"
    }

    func playGreeting() {
        playMotion("greeting")
    }

    func playThinking() {
        setExpression(.thinking)
        playMotion("thinking")
    }
}
