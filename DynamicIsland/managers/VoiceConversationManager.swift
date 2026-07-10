import AVFoundation
import Speech
import Foundation
import Defaults

// MARK: - 语音识别供应商

enum SpeechProvider: String, CaseIterable, Identifiable, Defaults.Serializable {
    case system       = "系统语音识别"
    case openaiWhisper = "OpenAI Whisper"

    var id: String { rawValue }

    var needsApiKey: Bool {
        switch self {
        case .system:       return false
        case .openaiWhisper: return true
        }
    }
}

// MARK: - 对话模式

enum VoiceMode: String, CaseIterable, Identifiable, Defaults.Serializable {
    case manual     = "手动录音"
    case continuous = "实时对话"

    var id: String { rawValue }
}

// MARK: - 实时对话管理器

@MainActor
final class VoiceConversationManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    static let shared = VoiceConversationManager()

    // 状态
    @Published var isActive: Bool = false
    @Published var liveText: String = ""
    @Published var isSpeaking: Bool = false
    @Published var lastResponse: String = ""

    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechSynthesizer = AVSpeechSynthesizer()

    // 静音检测
    private var pauseTimer: Timer?
    private var lastAudioLevel: Float = 0
    private let pauseThreshold: TimeInterval = 1.5  // 1.5秒静音后自动发送

    private var onSendHandler: ((String) -> Void)?

    // MARK: - Public API

    /// 启动实时对话模式
    func startConversation(onSend: @escaping (String) -> Void) {
        onSendHandler = onSend
        isActive = true
        liveText = ""

        let provider = Defaults[.speechProvider]

        switch provider {
        case .system:
            startSystemRecognition()
        case .openaiWhisper:
            startWhisperStreaming()
        }
    }

    /// 停止对话模式
    func stopConversation() {
        isActive = false
        recognitionTask?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        audioRecorder?.stop()
        audioRecorder = nil
        pauseTimer?.invalidate()
        stopSpeaking()
    }

    /// 朗读并继续监听
    func speakAndListen(_ text: String) {
        lastResponse = text
        stopSpeaking()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95

        isSpeaking = true
        speechSynthesizer.speak(utterance)

        // 朗读完成后重新开始监听
        DispatchQueue.global().async { [weak self] in
            while self?.speechSynthesizer.isSpeaking == true {
                Thread.sleep(forTimeInterval: 0.1)
            }
            DispatchQueue.main.async {
                self?.isSpeaking = false
                // 如果是实时对话模式且仍然活跃，自动开始下一轮
                if self?.isActive == true && Defaults[.voiceMode] == .continuous {
                    // 发送完毕，继续监听
                }
            }
        }
    }

    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    // MARK: - 系统语音识别（实时流式）

    private func startSystemRecognition() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                print("❌ 语音识别未授权")
                return
            }
            DispatchQueue.main.async {
                self?.startAudioEngine()
            }
        }
    }

    private func startAudioEngine() {
        let engine = AVAudioEngine()
        audioEngine = engine

        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN")) ?? SFSpeechRecognizer()!
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true  // 实时返回部分结果

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)

            // 检测音量用于静音判断
            let level = buffer.floatChannelData?.pointee.pointee ?? 0
            DispatchQueue.main.async { [weak self] in
                self?.handleAudioLevel(abs(level))
            }
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let text = result?.bestTranscription.formattedString {
                    self?.liveText = text
                    // 重置静音计时器
                    self?.resetPauseTimer()
                }
                if error != nil || result?.isFinal == true {
                    // 识别结束
                }
            }
        }

        try? engine.start()
    }

    private func handleAudioLevel(_ level: Float) {
        lastAudioLevel = level
    }

    private func resetPauseTimer() {
        pauseTimer?.invalidate()
        guard Defaults[.voiceMode] == .continuous else { return }

        pauseTimer = Timer.scheduledTimer(withTimeInterval: pauseThreshold, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.autoSend()
            }
        }
    }

    private func autoSend() {
        let text = liveText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, isActive else { return }

        // 重置
        let message = liveText
        liveText = ""

        // 系统模式下开始新的识别
        recognitionTask?.cancel()
        recognitionTask = nil

        onSendHandler?(message)
    }

    // MARK: - OpenAI Whisper 流式识别

    private func startWhisperStreaming() {
        let apiKey = Defaults[.speechApiKey]
        guard !apiKey.isEmpty else {
            print("❌ Whisper API Key 未配置")
            return
        }

        // Whisper 不支持真正的流式，使用分块上传
        // 录制短片段 → 上传 → 返回文字 → 重复
        startRecordingChunks(apiKey: apiKey)
    }

    private func startRecordingChunks(apiKey: String) {
        let fileName = "whisper_chunk_\(Date().timeIntervalSince1970).wav"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false
        ]

        audioRecorder = try? AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record(forDuration: 3.0)  // 每3秒一段
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard flag else { return }
        let url = recorder.url
        sendToWhisper(url: url)

        // 继续下一段
        if isActive && Defaults[.voiceMode] == .continuous {
            startRecordingChunks(apiKey: Defaults[.speechApiKey])
        }
    }

    private func sendToWhisper(url: URL) {
        let apiKey = Defaults[.speechApiKey]
        guard !apiKey.isEmpty, let audioData = try? Data(contentsOf: url) else { return }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\nwhisper-1\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\nzh\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\nContent-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["text"] as? String else { return }
            DispatchQueue.main.async {
                self?.liveText += text
                try? FileManager.default.removeItem(at: url)
            }
        }.resume()
    }
}
