import AVFoundation
import Speech
import Foundation
import Defaults

// MARK: - 语音识别供应商

enum SpeechProvider: String, CaseIterable, Identifiable, Defaults.Serializable {
    case system        = "系统语音识别"
    case openaiWhisper = "OpenAI Whisper"
    case alibabaNls    = "阿里云语音识别"
    case baiduAsr      = "百度语音识别"
    case iflytek       = "讯飞语音听写"
    case bytedance     = "火山引擎 (豆包)"

    var id: String { rawValue }

    var needsApiKey: Bool {
        switch self {
        case .system:        return false
        case .openaiWhisper: return true
        case .alibabaNls:    return true
        case .baiduAsr:      return true
        case .iflytek:       return true
        case .bytedance:     return true
        }
    }
    
    var apiDoc: String {
        switch self {
        case .system:        return ""
        case .openaiWhisper: return "与 ChatGPT 共用 API Key"
        case .alibabaNls:    return "从阿里云智能语音交互控制台获取 AppKey + AccessToken"
        case .baiduAsr:      return "从百度AI开放平台获取 API Key + Secret Key"
        case .iflytek:       return "从讯飞开放平台获取 APPID + APIKey"
        case .bytedance:     return "从火山引擎控制台获取 AppID + AccessToken"
        }
    }
}

// MARK: - 对话模式

enum VoiceMode: String, CaseIterable, Identifiable, Defaults.Serializable {
    case manual     = "手动录音"
    case continuous = "实时对话"

    var id: String { rawValue }
}



// MARK: - TTS 语音合成供应商

enum TTSSynthesisProvider: String, CaseIterable, Identifiable, Defaults.Serializable {
    case system    = "系统语音合成"
    case bytedance = "火山引擎 (豆包)"

    var id: String { rawValue }

    var needsApiKey: Bool {
        switch self {
        case .system:    return false
        case .bytedance: return true
        }
    }

    var apiDoc: String {
        switch self {
        case .system:    return ""
        case .bytedance: return "与语音识别共用 AppID + AccessToken"
        }
    }
}

// MARK: - 豆包 TTS 音色

enum TTSVoiceType: String, CaseIterable, Identifiable, Defaults.Serializable {
    case BV001 = "豆包女声 (默认)"
    case BV002 = "豆包男声"
    case BV003 = "知性女声"
    case BV004 = "醇厚男声"
    case BV405 = "甜美女生"
    case BV406 = "阳光男声"
    case BV007 = "亲切女声"
    case BV008 = "沉稳男声"

    var id: String { rawValue }

    var voiceCode: String {
        switch self {
        case .BV001: return "BV001_streaming"
        case .BV002: return "BV002_streaming"
        case .BV003: return "BV003_streaming"
        case .BV004: return "BV004_streaming"
        case .BV405: return "BV405_streaming"
        case .BV406: return "BV406_streaming"
        case .BV007: return "BV007_streaming"
        case .BV008: return "BV008_streaming"
        }
    }
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

        resolveProvider()
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

        let ttsProvider = Defaults[.ttsProvider]

        switch ttsProvider {
        case .bytedance:
            let tts = VolcanoTTSService.shared
            isSpeaking = true
            tts.synthesize(text: text) { [weak self] in
                self?.isSpeaking = false
                self?.restartRecognitionIfNeeded()
            }
        case .system:
            fallthrough
        default:
            speakWithSystemTTS(text)
        }
    }

    /// 连续对话模式下，TTS 播完后重新启动语音识别
    private func restartRecognitionIfNeeded() {
        guard isActive, Defaults[.voiceMode] == .continuous else { return }
        // 重置录音状态并启动新一轮识别
        liveText = ""
        resolveProvider()
    }

    private func speakWithSystemTTS(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95

        isSpeaking = true
        speechSynthesizer.speak(utterance)

        DispatchQueue.global().async { [weak self] in
            while self?.speechSynthesizer.isSpeaking == true {
                Thread.sleep(forTimeInterval: 0.1)
            }
            DispatchQueue.main.async {
                self?.isSpeaking = false
                self?.restartRecognitionIfNeeded()
            }
        }
    }

    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        VolcanoTTSService.shared.stop()
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

    private func resolveProvider() {
        let provider = Defaults[.speechProvider]
        switch provider {
        case .system:        startSystemRecognition()
        case .openaiWhisper: startWhisperStreaming()
        case .alibabaNls:    startAlibabaRecognition()
        case .baiduAsr:      startBaiduRecognition()
        case .iflytek:       startIflytekRecognition()
        case .bytedance:     startBytedanceRecognition()
        }
    }

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
        audioRecorder?.record(forDuration: 3.0)
    }

    // AVAudioRecorderDelegate — 统一处理录音完成
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard flag else { return }
        let url = recorder.url
        let provider = Defaults[.speechProvider]

        switch provider {
        case .openaiWhisper:
            sendToWhisper(url: url)
        case .alibabaNls:
            sendToAlibaba(url: url, appKey: Defaults[.speechApiKey], token: Defaults[.speechApiSecret])
        case .baiduAsr:
            sendToBaidu(url: url, apiKey: Defaults[.speechApiKey], secretKey: Defaults[.speechApiSecret])
        case .iflytek:
            sendToIflytek(url: url, appId: Defaults[.speechApiKey], apiKey: Defaults[.speechApiSecret])
        case .bytedance:
            sendToBytedance(url: url, appId: Defaults[.speechApiKey], token: Defaults[.speechApiSecret])
        default:
            break
        }

        // 继续下一段
        if isActive && Defaults[.voiceMode] == .continuous {
            resolveProvider()
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

        // MARK: - 阿里云 NLS 识别

        private func startAlibabaRecognition() {
            let appKey = Defaults[.speechApiKey]
            let accessToken = Defaults[.speechApiSecret]
            guard !appKey.isEmpty, !accessToken.isEmpty else {
                print("❌ 阿里云语音识别未配置 AppKey/Token")
                return
            }
            startRecordingChunksForProvider(provider: "alibaba")
        }

        private func sendToAlibaba(url: URL, appKey: String, token: String) {
            guard let audioData = try? Data(contentsOf: url) else { return }
            // Base64 encode
            let base64 = audioData.base64EncodedString()

            var request = URLRequest(url: URL(string: "https://nls-gateway-cn-shanghai.aliyuncs.com/stream/v1/asr?appkey=\(appKey)")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "X-NLS-Token")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "payload": [
                    "enable_intermediate_result": true,
                    "enable_punctuation_prediction": true,
                    "enable_inverse_text_normalization": true
                ],
                "context": ["audio": ["audio_format": "wav", "sample_rate": 16000]],
                "audio": base64
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let result = json["result"] as? String else { return }
                DispatchQueue.main.async {
                    self?.liveText += result
                    try? FileManager.default.removeItem(at: url)
                }
            }.resume()
        }

        // MARK: - 百度语音识别

        private func startBaiduRecognition() {
            let apiKey = Defaults[.speechApiKey]
            let secretKey = Defaults[.speechApiSecret]
            guard !apiKey.isEmpty, !secretKey.isEmpty else {
                print("❌ 百度语音识别未配置")
                return
            }
            startRecordingChunksForProvider(provider: "baidu")
        }

        private func sendToBaidu(url: URL, apiKey: String, secretKey: String) {
            guard let audioData = try? Data(contentsOf: url) else { return }
            let base64 = audioData.base64EncodedString()
            let len = audioData.count

            // 获取 access_token
            let tokenURL = "https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=\(apiKey)&client_secret=\(secretKey)"

            URLSession.shared.dataTask(with: URL(string: tokenURL)!) { [weak self] tokenData, _, _ in
                guard let tokenData,
                      let tokenJson = try? JSONSerialization.jsonObject(with: tokenData) as? [String: Any],
                      let accessToken = tokenJson["access_token"] as? String else { return }

                var request = URLRequest(url: URL(string: "https://vop.baidu.com/server_api?dev_pid=1537&cuid=atoll_mac&token=\(accessToken)")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body: [String: Any] = [
                    "format": "wav",
                    "rate": 16000,
                    "channel": 1,
                    "speech": base64,
                    "len": len
                ]
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)

                URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
                    guard let data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let result = json["result"] as? [String] else { return }
                    DispatchQueue.main.async {
                        self?.liveText += result.joined()
                        try? FileManager.default.removeItem(at: url)
                    }
                }.resume()
            }.resume()
        }

        // MARK: - 讯飞语音听写

        private func startIflytekRecognition() {
            let appId = Defaults[.speechApiKey]
            let apiKey = Defaults[.speechApiSecret]
            guard !appId.isEmpty, !apiKey.isEmpty else {
                print("❌ 讯飞语音未配置")
                return
            }
            startRecordingChunksForProvider(provider: "iflytek")
        }

        private func sendToIflytek(url: URL, appId: String, apiKey: String) {
            guard let audioData = try? Data(contentsOf: url) else { return }
            let base64 = audioData.base64EncodedString()

            let host = "iat-api.xfyun.cn"
            var request = URLRequest(url: URL(string: "https://\(host)/v2/iat")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "common": ["app_id": appId],
                "business": [
                    "language": "zh_cn",
                    "domain": "iat",
                    "accent": "mandarin",
                    "ptt": 0,
                    "rlang": "zh-cn"
                ],
                "data": [
                    "status": 2,
                    "format": "audio/L16;rate=16000",
                    "encoding": "raw",
                    "audio": base64
                ]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let code = json["code"] as? Int, code == 0,
                      let dataObj = json["data"] as? [String: Any],
                      let result = dataObj["result"] as? [String: Any],
                      let ws = result["ws"] as? [[String: Any]] else { return }
                let text = ws.compactMap { ($0["cw"] as? [[String: Any]])?.first?["w"] as? String }.joined()
                DispatchQueue.main.async {
                    self?.liveText += text
                    try? FileManager.default.removeItem(at: url)
                }
            }.resume()
        }

        // MARK: - 通用分块录音（所有第三方供应商共用）

        private func startRecordingChunksForProvider(provider: String) {
            let fileName = "\(provider)_chunk_\(Date().timeIntervalSince1970).wav"
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
            audioRecorder?.record(forDuration: 4.0)
        }


    // MARK: - 火山引擎 (豆包) 语音识别

    private func startBytedanceRecognition() {
        let appId = Defaults[.speechApiKey]
        let token = Defaults[.speechApiSecret]
        guard !appId.isEmpty, !token.isEmpty else {
            print("❌ 火山引擎语音识别未配置 AppID/Token")
            return
        }
        startRecordingChunksForProvider(provider: "bytedance")
    }

    private func sendToBytedance(url: URL, appId: String, token: String) {
        guard let audioData = try? Data(contentsOf: url) else { return }
        var request = URLRequest(url: URL(string: "https://openspeech.bytedance.com/api/v1/asr?appid=\(appId)")!)
        request.httpMethod = "POST"
        request.setValue("Bearer; \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        var body = Data()
        body.append(Data([0x11, 0x10, 0x10, 0x00]))
        body.append(audioData)
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            if let error {
                print("❌ 火山引擎 ASR 请求失败: \(error)")
                DispatchQueue.main.async {
                    self.liveText += "[语音识别网络错误] "
                    try? FileManager.default.removeItem(at: url)
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("❌ 火山引擎 ASR HTTP \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    self.liveText += "[语音识别服务异常] "
                    try? FileManager.default.removeItem(at: url)
                }
                return
            }

            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                print("❌ 火山引擎 ASR 解析失败")
                DispatchQueue.main.async {
                    try? FileManager.default.removeItem(at: url)
                }
                return
            }

            // 检查错误码
            if let code = json["code"] as? Int, code != 0 {
                let message = json["message"] as? String ?? "未知错误"
                print("❌ 火山引擎 ASR 错误: code=\(code), message=\(message)")
                DispatchQueue.main.async {
                    self.liveText += "[识别失败: \(message)] "
                    try? FileManager.default.removeItem(at: url)
                }
                return
            }

            if let utterances = json["utterances"] as? [[String: Any]] {
                let text = utterances.compactMap { $0["text"] as? String }.joined()
                DispatchQueue.main.async {
                    self.liveText += text
                    try? FileManager.default.removeItem(at: url)
                }
            } else if let result = json["result"] as? [String: Any],
                      let text = result["text"] as? String {
                // 部分旧版 API 返回格式
                DispatchQueue.main.async {
                    self.liveText += text
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }.resume()
    }


}