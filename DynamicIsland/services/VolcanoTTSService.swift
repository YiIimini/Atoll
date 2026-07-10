import Foundation
import AVFoundation
import Defaults

// MARK: - 火山引擎 TTS 共享服务
/// 统一管理火山引擎 TTS 合成与播放，供 VoiceConversationManager 和 ScreenAssistantManager 共用

final class VolcanoTTSService: NSObject {
    static let shared = VolcanoTTSService()

    private var audioPlayer: AVAudioPlayer?
    private var onComplete: (() -> Void)?

    /// 获取有效的 TTS 凭证 — TTS 专用 Key 优先，否则回退 ASR Key（共用同一套火山引擎 AppID+Token）
    static func resolveCredentials() -> (appId: String, token: String)? {
        let ttsKey = Defaults[.ttsApiKey]
        let ttsSecret = Defaults[.ttsApiSecret]
        if !ttsKey.isEmpty, !ttsSecret.isEmpty {
            return (ttsKey, ttsSecret)
        }
        // fallback to ASR credentials
        let asrKey = Defaults[.speechApiKey]
        let asrSecret = Defaults[.speechApiSecret]
        if !asrKey.isEmpty, !asrSecret.isEmpty {
            return (asrKey, asrSecret)
        }
        return nil
    }

    /// 合成并播放 TTS
    func synthesize(text: String, completion: @escaping () -> Void) {
        guard let creds = Self.resolveCredentials() else {
            print("❌ 火山引擎 TTS 未配置凭证")
            completion()
            return
        }

        let voiceType = Defaults[.ttsVoiceType]
        let reqId = UUID().uuidString

        var request = URLRequest(url: URL(string: "https://openspeech.bytedance.com/api/v1/tts")!)
        request.httpMethod = "POST"
        request.setValue("Bearer; \(creds.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "app": [
                "appid": creds.appId,
                "token": creds.token,
                "cluster": "volcano_tts"
            ],
            "user": ["uid": "atoll_user"],
            "audio": [
                "voice_type": voiceType.voiceCode,
                "encoding": "mp3",
                "speed_ratio": 1.0,
                "rate": 24000
            ],
            "request": [
                "reqid": reqId,
                "text": text,
                "text_type": "plain",
                "operation": "query"
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("🎤 火山引擎 TTS 合成: \(text.prefix(50))...")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            // 检查 HTTP 状态码
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                guard (200...299).contains(statusCode) else {
                    print("❌ 火山引擎 TTS HTTP \(statusCode)")
                    DispatchQueue.main.async { completion() }
                    return
                }
                // 检查 Content-Type — 错误时可能返回 JSON
                if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String,
                   contentType.contains("application/json"),
                   let data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let code = json["code"] as? Int, code != 3000 {
                    print("❌ 火山引擎 TTS 错误: code=\(code), message=\(json["message"] as? String ?? "未知")")
                    DispatchQueue.main.async { completion() }
                    return
                }
            }

            if let error {
                print("❌ 火山引擎 TTS 请求失败: \(error)")
                DispatchQueue.main.async { completion() }
                return
            }

            guard let data else {
                print("❌ 火山引擎 TTS 返回空数据")
                DispatchQueue.main.async { completion() }
                return
            }

            // 检查是否是 JSON 错误响应（部分代理/CDN 不会设置 Content-Type）
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let code = json["code"] as? Int, code != 3000 {
                print("❌ 火山引擎 TTS 错误: code=\(code), message=\(json["message"] as? String ?? "未知")")
                DispatchQueue.main.async { completion() }
                return
            }

            DispatchQueue.main.async {
                self.play(data: data, completion: completion)
            }
        }.resume()
    }

    /// 停止播放
    func stop() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
        onComplete?()
        onComplete = nil
    }

    private func play(data: Data, completion: @escaping () -> Void) {
        onComplete = completion
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 0.9
            audioPlayer?.play()
            print("🔊 火山引擎 TTS 播放中...")
        } catch {
            print("❌ 播放 TTS 音频失败: \(error)")
            completion()
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension VolcanoTTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.onComplete?()
            self?.onComplete = nil
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ TTS 解码错误: \(error?.localizedDescription ?? "未知")")
        DispatchQueue.main.async { [weak self] in
            self?.onComplete?()
            self?.onComplete = nil
        }
    }
}
