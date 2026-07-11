import SwiftUI
import AppKit
import WebKit

// MARK: - Live2D 透明悬浮窗

final class Live2DAvatarWindow: NSWindow {
    private var webView: WKWebView?
    private var bridge: Live2DBridge?
    var onTap: (() -> Void)?

    init() {
        let size: CGFloat = 400
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: size, height: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        setup()
    }

    private func setup() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        ignoresMouseEvents = false

        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        bridge = Live2DBridge(window: self)
        userContentController.add(bridge!, name: "atoll")
        config.userContentController = userContentController

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.setValue(false, forKey: "drawsBackground")
        wv.translatesAutoresizingMaskIntoConstraints = false
        
        contentView = wv
        webView = wv

        wv.loadHTMLString(live2dHTML, baseURL: nil)

        center()
        var frame = self.frame
        frame.origin.y -= 120
        setFrame(frame, display: true)
    }

    func sendToJS(_ dict: [String: Any]) {
        guard let json = try? JSONSerialization.data(withJSONObject: dict),
              let js = String(data: json, encoding: .utf8) else { return }
        webView?.evaluateJavaScript("window.postMessage(\(js), '*')", completionHandler: nil)
    }
}

// MARK: - Swift ↔ JS Bridge

final class Live2DBridge: NSObject, WKScriptMessageHandler {
    weak var window: Live2DAvatarWindow?

    init(window: Live2DAvatarWindow) {
        self.window = window
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }

        DispatchQueue.main.async {
            switch type {
            case "pageReady":
                print("🎭 Live2D page ready")
                self.window?.sendToJS(["type": "init", "modelUrl": ""])
            case "ready":
                print("🎭 Live2D model loaded: \(body["success"] ?? false)")
            case "tap":
                self.window?.onTap?()
            default:
                break
            }
        }
    }
}
