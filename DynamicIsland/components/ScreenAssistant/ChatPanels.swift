/*
 * Atoll (DynamicIsland)
 * Copyright (C) 2024-2026 Atoll Contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import AppKit
import SwiftUI
import Defaults

private func applyChatPanelCornerMask(_ view: NSView, radius: CGFloat) {
    view.wantsLayer = true
    view.layer?.masksToBounds = true
    view.layer?.cornerRadius = radius
    view.layer?.backgroundColor = NSColor.clear.cgColor
    if #available(macOS 13.0, *) {
        view.layer?.cornerCurve = .continuous
    }
}

// MARK: - Chat Messages Panel (Left Side)
class ChatMessagesPanel: NSPanel {
    
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        
        setupWindow()
        setupContentView()
    }
    
    override var canBecomeKey: Bool {
        return false  // Don't steal focus from input panel
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    private func setupWindow() {
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        level = .floating
        isMovableByWindowBackground = true  // Draggable by background
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isFloatingPanel = true
        
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary
        ]
        
        ScreenCaptureVisibilityManager.shared.register(self, scope: .panelsOnly)
        
        acceptsMouseMovedEvents = true
    }
    
    private func setupContentView() {
        let contentView = ChatMessagesView()
        let hostingView = NSHostingView(rootView: contentView)
        applyChatPanelCornerMask(hostingView, radius: 16)
        self.contentView = hostingView
        
        // Set size for chat messages panel (wider and taller)
        let preferredSize = CGSize(width: 600, height: 500)
        hostingView.setFrameSize(preferredSize)
        setContentSize(preferredSize)
    }
    
    /// 将聊天面板定位在输入面板上方（默认居中悬浮）
    func positionAboveInput() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let panelFrame = frame
        
        // 水平居中
        let xPosition = (screenFrame.width - panelFrame.width) / 2 + screenFrame.minX
        // 垂直：位于输入框上方（输入框在底部 100pt，输入框高约 60pt，间距 16pt）
        let inputPanelBottom = screenFrame.minY + 100
        let inputPanelTop = inputPanelBottom + 100  // 输入面板顶部估算
        let yPosition = inputPanelTop + 16  // 上方 16pt 间距
        
        setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
    }
    
    deinit {
        ScreenCaptureVisibilityManager.shared.unregister(self)
    }
}

// MARK: - Chat Input Panel (Center)
class ChatInputPanel: NSPanel {
    
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        
        setupWindow()
        setupContentView()
    }
    
    override var canBecomeKey: Bool {
        return true  // Can receive focus for text input
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    // Handle ESC key globally for the panel
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            ScreenAssistantManager.shared.closePanels()
        } else {
            super.keyDown(with: event)
        }
    }
    
    private func setupWindow() {
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        level = .floating
        isMovableByWindowBackground = true  // Enable dragging
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isFloatingPanel = true
        
        styleMask.insert(.fullSizeContentView)
        
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary
        ]
        
        ScreenCaptureVisibilityManager.shared.register(self, scope: .panelsOnly)
        
        acceptsMouseMovedEvents = true
    }
    
    private func setupContentView() {
        let contentView = ChatInputView()
        let hostingView = NSHostingView(rootView: contentView)
        applyChatPanelCornerMask(hostingView, radius: 16)
        self.contentView = hostingView
        
        // Set compact size for single-line input panel
        let preferredSize = CGSize(width: 500, height: 60)
        hostingView.setFrameSize(preferredSize)
        setContentSize(preferredSize)
    }
    
    func positionInCenter() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let panelFrame = frame
        
        // Position in the center-bottom of the screen (like a search bar)
        let xPosition = (screenFrame.width - panelFrame.width) / 2 + screenFrame.minX
        let yPosition = screenFrame.minY + 100 // 100pt from bottom
        
        setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
    }
    
    deinit {
        ScreenCaptureVisibilityManager.shared.unregister(self)
    }
}

// MARK: - Chat Messages View (Redesigned for standalone panel)
struct ChatMessagesView: View {
    @ObservedObject var screenAssistantManager = ScreenAssistantManager.shared
    @ObservedObject var voiceManager = VoiceConversationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 可拖动的标题栏
            HStack {
                // 拖动提示图标
                Image(systemName: "line.3.horizontal")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))
                    .help("拖动此处移动窗口")
                
                Text("AI Assistant")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()

                Button(action: {
                    screenAssistantManager.resetConversationContext()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                        Text("Reset Context")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(8)
                }
                .disabled(screenAssistantManager.isLoading)
                .buttonStyle(PlainButtonStyle())
                .help("Clear conversation and attachments")
                
                Button(action: {
                    screenAssistantManager.closePanels()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close assistant")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Chat content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if screenAssistantManager.chatMessages.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue.opacity(0.6))
                                
                                VStack(spacing: 8) {
                                    Text("AI Assistant")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("AI 助手随时为你服务")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 80)
                        } else {
                            ForEach(screenAssistantManager.chatMessages) { message in
                                StreamingChatMessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if screenAssistantManager.isLoading {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("AI 正在思考...")
                                            .font(.body.weight(.medium))
                                            .foregroundColor(.primary.opacity(0.8))
                                        Text("请稍候")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                .onChange(of: screenAssistantManager.chatMessages.count) { _, _ in
                    if let lastMessage = screenAssistantManager.chatMessages.last {
                        withAnimation(.easeOut(duration: 0.5)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: screenAssistantManager.isLoading) { _, _ in
                    if screenAssistantManager.isLoading {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                if let lastMessage = screenAssistantManager.chatMessages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(ChatPanelsVisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Chat Input View (Single Line Panel)
struct ChatInputView: View {
    @ObservedObject var screenAssistantManager = ScreenAssistantManager.shared
    @State private var messageText = ""
    @State private var isDraggingFiles = false
    @State private var showingApiKeyAlert = false
    @StateObject private var cmdExecutor = SystemCommandExecutor.shared
    @State private var pendingCmd: SystemCommand? = nil
    @State private var pendingCmdArg: String? = nil
    @FocusState private var isTextFieldFocused: Bool
    
    // Current model information
    private var currentProvider: AIModelProvider {
        Defaults[.selectedAIProvider]
    }
    
    private var currentModel: AIModel? {
        Defaults[.selectedAIModel]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Current model indicator
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: iconForProvider(currentProvider))
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(currentModel?.name ?? currentProvider.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if currentModel?.supportsThinking == true && Defaults[.enableThinkingMode] {
                        Text("• Thinking")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
                
                Spacer()
                
                Button("模型设置", action: openModelSelection)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.05))
            
            // File attachments row (if any)
            if !screenAssistantManager.attachedFiles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(screenAssistantManager.attachedFiles) { file in
                            AttachedFileChip(file: file) {
                                screenAssistantManager.removeFile(file)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.05))
                
                Divider()
            }
            
            // Single line input row
            HStack(spacing: 12) {
                // Add files button
                AddFilesButton()
                
                // Screenshot snipping button
                ScreenshotButton()
                
                // Text input - SINGLE LINE
                TextField("Ask me anything...", text: $messageText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .onSubmit {
                        sendMessage()
                    }
                
                // Model selection button
                Button(action: openModelSelection) {
                    Image(systemName: "brain.head.profile.fill")
                        .foregroundColor(.purple)
                        .font(.system(size: 20))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Choose AI model")
                
                // 语音输入按钮
                VoiceInputButton()
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                        .padding(8)
                        .background(canSend ? Color.blue : Color.gray)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canSend)
            }
            .padding(12)
        }
        .background(ChatPanelsVisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
        .onDrop(of: [.fileURL], isTargeted: $isDraggingFiles) { providers in
            handleFilesDrop(providers)
        }
        .alert("API Key Required", isPresented: $showingApiKeyAlert) {
            Button("Open Model Settings") {
                openModelSelection()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please configure your API key for the selected AI provider in model settings.")
        }
        .alert(item: $pendingCmd) { cmd in
            Alert(
                title: Text(cmd.rawValue),
                message: Text("确认执行：\(cmd.description)"),
                primaryButton: .destructive(Text("执行")) {
                    let result = cmdExecutor.execute(cmd, arg: pendingCmdArg)
                    screenAssistantManager.addAssistantMessage(result)
                    messageText = ""
                },
                secondaryButton: .cancel(Text("取消")) {
                    messageText = ""
                }
            )
        }
.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("voiceInputReady"))) { _ in
            if UserDefaults.standard.bool(forKey: "voiceInputReady") {
                let text = UserDefaults.standard.string(forKey: "voiceInputPending") ?? ""
                UserDefaults.standard.set(false, forKey: "voiceInputReady")
                UserDefaults.standard.removeObject(forKey: "voiceInputPending")
                if !text.isEmpty {
                    messageText = text
                }
            }
        }
    }
    
    private func iconForProvider(_ provider: AIModelProvider) -> String {
        switch provider {
        case .gemini: return "sparkles"
        case .openai: return "brain.head.profile"
        case .claude: return "doc.text"
        case .local: return "server.rack"
        case .groq: return "bolt.fill"
        case .deepseek: return "wave.3.right"
        case .openrouter: return "globe"
        case .qwen: return "text.bubble"
        case .moonshot: return "moon.stars"
        case .zhipu: return "brain.head.profile"
        case .baichuan: return "scroll"
        case .yi: return "sparkle.magnifyingglass"
        case .minimax: return "waveform.and.mic"
        }
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !screenAssistantManager.attachedFiles.isEmpty
    }
    
    private func sendMessage() {
        // Check if API key is configured for the selected provider
        let provider = Defaults[.selectedAIProvider]
        var apiKey = ""
        
        switch provider {
        case .gemini:
            apiKey = Defaults[.geminiApiKey]
        case .openai:
            apiKey = Defaults[.openaiApiKey]
        case .claude:
            apiKey = Defaults[.claudeApiKey]
        case .local:
            // Local models don't need API keys
            apiKey = "local"
        case .groq:
            apiKey = Defaults[.groqApiKey]
        case .deepseek:
            apiKey = Defaults[.deepseekApiKey]
        case .openrouter:
            apiKey = Defaults[.openrouterApiKey]
        case .qwen:
            apiKey = Defaults[.qwenApiKey]
        case .moonshot:
            apiKey = Defaults[.moonshotApiKey]
        case .zhipu:
            apiKey = Defaults[.zhipuApiKey]
        case .baichuan:
            apiKey = Defaults[.baichuanApiKey]
        case .yi:
            apiKey = Defaults[.yiApiKey]
        case .minimax:
            apiKey = Defaults[.minimaxApiKey]
        }
        
        if apiKey.isEmpty {
            showingApiKeyAlert = true
            return
        }
        
        // Prepare the message
        let userMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if userMessage.isEmpty && screenAssistantManager.attachedFiles.isEmpty {
            return
        }
        
        // Check for system command first
        if let (cmd, arg) = CommandMatcher.match(userMessage) {
            pendingCmd = cmd
            pendingCmdArg = arg
            return
        }
        
        // Send message through manager
        screenAssistantManager.sendMessage(userMessage)
        messageText = ""
    }
    
    private func openModelSelection() {
        let panel = ModelSelectionPanel()
        panel.positionInCenter()
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        
        // Activate the app to ensure proper focus handling
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func handleFilesDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                if let url = url {
                    DispatchQueue.main.async {
                        screenAssistantManager.addFiles([url])
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Enhanced Chat Message Bubble (No Auto-Streaming)
struct StreamingChatMessageBubble: View {
    @ObservedObject var _screenAssistantManager = ScreenAssistantManager.shared
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer()
            }
            
            // Avatar
            if !message.isFromUser {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 8) {
                // Header with name and timestamp
                HStack {
                    Text(message.isFromUser ? "You" : "AI Assistant")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(message.isFromUser ? .blue : .green)
                    
                    Spacer()
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // File attachments (if any)
                if let files = message.attachedFiles, !files.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(files.prefix(3)) { file in
                            HStack(spacing: 4) {
                                Image(systemName: file.type.iconName)
                                    .font(.caption2)
                                Text(file.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if files.count > 3 {
                            Text("+\(files.count - 3) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Message content - NO AUTO STREAMING
                MarkdownText(content: message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isFromUser ? Color.blue : Color.gray.opacity(0.15))
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
                
                // 朗读按钮（仅 AI 回复显示）
                if !message.isFromUser && !message.content.isEmpty {
                    HStack {
                        SpeakButton(text: message.content, screenAssistantManager: _screenAssistantManager)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: 400, alignment: message.isFromUser ? .trailing : .leading)
            
            // User avatar
            if message.isFromUser {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Note: Shared Components (MarkdownText, AttachedFileChip, AddFilesButton, RecordingButton, ApiKeyAlertView) 
// are defined in ScreenAssistantPanel.swift to avoid redeclaration conflicts.

// MARK: - Screenshot Button Component
struct ScreenshotButton: View {
    @ObservedObject var screenAssistantManager = ScreenAssistantManager.shared
    @StateObject private var screenshotTool = ScreenshotSnippingTool.shared
    @State private var showingScreenshotOptions = false
    
    var body: some View {
        HStack(spacing: 4) {
            // Main screenshot button
            Button(action: startQuickScreenshot) {
                Image(systemName: getIconName())
                    .foregroundColor(getIconColor())
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Take area screenshot")
            .disabled(screenshotTool.isSnipping)
            .scaleEffect(screenshotTool.isSnipping ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: screenshotTool.isSnipping)
            
            // Options dropdown button
            Button(action: { showingScreenshotOptions.toggle() }) {
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Screenshot options")
            .disabled(screenshotTool.isSnipping)
            .popover(isPresented: $showingScreenshotOptions) {
                ScreenshotOptionsPopover { type in
                    startScreenshot(type: type)
                    showingScreenshotOptions = false
                }
            }
        }
    }
    
    private func getIconName() -> String {
        if screenshotTool.isSnipping {
            return "camera.viewfinder"
        } else {
            return "camera.aperture"
        }
    }
    
    private func getIconColor() -> Color {
        if screenshotTool.isSnipping {
            return .red
        } else {
            return .green
        }
    }
    
    private func startQuickScreenshot() {
        // Default to area screenshot for quick action
        startScreenshot(type: .area)
    }
    
    private func startScreenshot(type: ScreenshotSnippingTool.ScreenshotType) {
        // Start snipping with direct callback (ScreenshotApp-based approach)
        screenshotTool.startSnipping(type: type) { [weak screenAssistantManager] screenshotURL in
            guard let manager = screenAssistantManager else {
                print("❌ ScreenshotTool: ScreenAssistantManager deallocated during callback")
                return
            }
            
            print("📁 ScreenshotTool: Adding \(type.displayName.lowercased()) screenshot to chat: \(screenshotURL.lastPathComponent)")
            manager.addFiles([screenshotURL])
            print("📸 \(type.displayName) screenshot captured and added to chat successfully")
        }
    }
}

// MARK: - Visual Effect View for Chat Panels (to avoid conflicts)
struct ChatPanelsVisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Screenshot Options Popover (Hidden from Screen Recording)
struct ScreenshotOptionsPopover: View {
    let onOptionSelected: (ScreenshotSnippingTool.ScreenshotType) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Screenshot Type")
                .font(.headline)
                .padding(.top, 8)
            
            VStack(spacing: 4) {
                ScreenshotOptionButton(
                    type: .area,
                    description: "Select an area",
                    onTap: onOptionSelected
                )
                
                ScreenshotOptionButton(
                    type: .window,
                    description: "Select a window",
                    onTap: onOptionSelected
                )
                
                ScreenshotOptionButton(
                    type: .full,
                    description: "Capture full screen",
                    onTap: onOptionSelected
                )
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 12)
        .frame(width: 200)
        .background(
            ScreenshotPopoverBackground()
        )
    }
}

// MARK: - Screenshot Option Button
struct ScreenshotOptionButton: View {
    let type: ScreenshotSnippingTool.ScreenshotType
    let description: String
    let onTap: (ScreenshotSnippingTool.ScreenshotType) -> Void
    
    var body: some View {
        Button(action: { onTap(type) }) {
            HStack(spacing: 12) {
                Image(systemName: type.iconName)
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .frame(width: 20, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
                .opacity(0.5)
        )
        .onHover { isHovered in
            // Add subtle hover effect if needed
        }
    }
}

// MARK: - Screenshot Popover Background (Hidden from Screen Recording)
struct ScreenshotPopoverBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            ScreenCaptureVisibilityManager.shared.register(window, scope: .panelsOnly)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            ScreenCaptureVisibilityManager.shared.register(window, scope: .panelsOnly)
        }
    }
    
    static func dismantleNSView(_ nsView: NSView, coordinator: ()) {
        if let window = nsView.window {
            ScreenCaptureVisibilityManager.shared.unregister(window)
        }
    }
}

// MARK: - 语音输入按钮（语音识别 → 转文字输入）

struct VoiceInputButton: View {
    @ObservedObject var screenAssistantManager = ScreenAssistantManager.shared
    @ObservedObject var voiceManager = VoiceConversationManager.shared
    
    private var isContinuousMode: Bool {
        Defaults[.voiceMode] == .continuous
    }
    
    var body: some View {
        Button(action: {
            if isContinuousMode {
                if voiceManager.isActive {
                    voiceManager.stopConversation()
                } else {
                    voiceManager.startConversation { message in
                        if !message.isEmpty {
                            screenAssistantManager.sendMessage(message)
                        }
                    }
                }
            } else {
                if screenAssistantManager.isRecording {
                    screenAssistantManager.finishVoiceInput()
                } else {
                    screenAssistantManager.startVoiceInput()
                }
            }
        }) {
            if isContinuousMode && voiceManager.isActive {
                // 实时对话激活 — 按钮变身律动球
                ZStack {
                    DreamOrbView(size: 36, previewMode: true)
                }
                .frame(width: 36, height: 36)
            } else {
                ZStack {
                    Circle()
                        .fill(buttonBackground)
                        .frame(width: 32, height: 32)
                    
                    if !isContinuousMode && screenAssistantManager.isTranscribing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    } else {
                        Image(systemName: buttonIcon)
                            .foregroundColor(buttonIconColor)
                            .font(.system(size: 14))
                    }
                }
                .frame(width: 32, height: 32)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .help(buttonHelp)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: voiceManager.isActive)
        .animation(.easeInOut(duration: 0.2), value: screenAssistantManager.isRecording)
        .onReceive(NotificationCenter.default.publisher(for: .voiceInputTranscribed)) { notif in
            if let text = notif.object as? String {
                UserDefaults.standard.set(text, forKey: "voiceInputPending")
                UserDefaults.standard.set(true, forKey: "voiceInputReady")
            }
        }
    }
    
    private var buttonBackground: Color {
        if isContinuousMode {
            return Color.purple.opacity(0.15)
        }
        return screenAssistantManager.isRecording ? Color.red : Color.blue.opacity(0.2)
    }
    
    private var buttonIcon: String {
        if isContinuousMode {
            return "mic.fill"
        }
        return screenAssistantManager.isRecording ? "stop.fill" : "mic.fill"
    }
    
    private var buttonIconColor: Color {
        if isContinuousMode {
            return .purple
        }
        return screenAssistantManager.isRecording ? .white : .blue
    }
    
    private var buttonHelp: String {
        if isContinuousMode {
            return voiceManager.isActive ? "点击停止实时对话" : "开始实时对话"
        }
        return screenAssistantManager.isRecording ? "停止录音并识别" : "语音输入"
    }
}

// MARK: - AI 回复朗读按钮

struct SpeakButton: View {
    let text: String
    @ObservedObject var voiceManager = VoiceConversationManager.shared
    @ObservedObject var screenAssistantManager = ScreenAssistantManager.shared
    
    var body: some View {
        Button(action: {
            if voiceManager.isActive && Defaults[.voiceMode] == .continuous {
                voiceManager.speakAndListen(text)
            } else {
                screenAssistantManager.speakText(text)
            }
        }) {
            Image(systemName: voiceManager.isSpeaking || screenAssistantManager.isSpeaking
                  ? "speaker.wave.3.fill" : "speaker.wave.2")
                .font(.system(size: 13))
                .foregroundColor(voiceManager.isSpeaking ? .green :
                                 screenAssistantManager.isSpeaking ? .green : .secondary)
                .padding(6)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .help(voiceManager.isSpeaking ? "停止朗读" : "朗读回复")
    }
}

// MARK: - 梦幻律动球（Siri 风格有机流体球）

struct DreamOrbView: View {
    let size: CGFloat
    var isConversationActive: Bool = false
    var previewMode: Bool = false
    
    @ObservedObject private var voiceManager = VoiceConversationManager.shared
    @State private var phase: Double = 0
    
    private let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()
    
    /// 仅在实时对话模式活跃时显示（previewMode 始终显示）
    private var isVisible: Bool {
        previewMode || isConversationActive || (voiceManager.isActive && Defaults[.voiceMode] == .continuous)
    }
    
    /// 对话活跃时动画更强烈
    private var intensity: Double {
        voiceManager.isActive ? 1.0 : 0.3
    }
    
    /// 多相位正弦波 — 模拟有机流体变形
    private func wave(_ t: Double, freq: Double, offset: Double = 0) -> Double {
        sin(t * freq + offset) * 0.5 + 0.5
    }
    
    @ViewBuilder
    var body: some View {
        if isVisible {
            ZStack {
                // 外层大面积柔光 — 虹彩
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(hue: phase.truncatingRemainder(dividingBy: 1), saturation: 0.8, brightness: 1.0).opacity(0.15 * intensity), location: 0),
                                .init(color: Color(hue: (phase + 0.15).truncatingRemainder(dividingBy: 1), saturation: 0.7, brightness: 0.95).opacity(0.15 * intensity), location: 0.15),
                                .init(color: Color(hue: (phase + 0.30).truncatingRemainder(dividingBy: 1), saturation: 0.9, brightness: 1.0).opacity(0.15 * intensity), location: 0.30),
                                .init(color: Color(hue: (phase + 0.50).truncatingRemainder(dividingBy: 1), saturation: 0.7, brightness: 0.9).opacity(0.15 * intensity), location: 0.50),
                                .init(color: Color(hue: (phase + 0.70).truncatingRemainder(dividingBy: 1), saturation: 0.8, brightness: 1.0).opacity(0.15 * intensity), location: 0.70),
                                .init(color: Color(hue: (phase + 0.85).truncatingRemainder(dividingBy: 1), saturation: 0.7, brightness: 0.95).opacity(0.15 * intensity), location: 0.85),
                                .init(color: Color(hue: (phase + 1.0).truncatingRemainder(dividingBy: 1), saturation: 0.8, brightness: 1.0).opacity(0.15 * intensity), location: 1.0),
                            ]),
                            center: .center,
                            angle: .degrees(phase * 90)
                        )
                    )
                    .frame(width: size * 1.9, height: size * 1.9)
                    .blur(radius: size * 0.35)
                    .scaleEffect(
                        x: 1 + 0.18 * intensity * sin(phase * 1.5),
                        y: 1 + 0.18 * intensity * cos(phase * 1.7)
                    )
                
                // 中层柔光
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hue: phase.truncatingRemainder(dividingBy: 1), saturation: 0.6, brightness: 1.0).opacity(0.25 * intensity),
                                Color(hue: (phase + 0.1).truncatingRemainder(dividingBy: 1), saturation: 0.5, brightness: 0.8).opacity(0.1 * intensity),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.9
                        )
                    )
                    .frame(width: size * 1.5, height: size * 1.5)
                    .blur(radius: size * 0.15)
                    .scaleEffect(1 + 0.1 * intensity * sin(phase * 2.0))
                
                // 主球体 — Siri 风格有机变形
                ZStack {
                    // 底层渐变
                    Circle()
                        .fill(
                            EllipticalGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(hue: phase.truncatingRemainder(dividingBy: 1), saturation: 0.5, brightness: 1.0), location: 0),
                                    .init(color: Color(hue: (phase + 0.08).truncatingRemainder(dividingBy: 1), saturation: 0.6, brightness: 0.85), location: 0.3),
                                    .init(color: Color(hue: (phase + 0.15).truncatingRemainder(dividingBy: 1), saturation: 0.7, brightness: 0.6), location: 0.6),
                                    .init(color: Color(hue: (phase + 0.25).truncatingRemainder(dividingBy: 1), saturation: 0.8, brightness: 0.4), location: 1.0),
                                ]),
                                center: UnitPoint(x: 0.35 + 0.15 * sin(phase * 1.3), y: 0.35 + 0.15 * cos(phase * 1.5))
                            )
                        )
                    
                    // 虹彩表面层 — 模拟肥皂泡
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(0.12), location: 0),
                                    .init(color: Color(hue: (phase + 0.1).truncatingRemainder(dividingBy: 1), saturation: 0.3, brightness: 1.0).opacity(0.1), location: 0.25),
                                    .init(color: .white.opacity(0.08), location: 0.5),
                                    .init(color: Color(hue: (phase + 0.6).truncatingRemainder(dividingBy: 1), saturation: 0.3, brightness: 1.0).opacity(0.1), location: 0.75),
                                    .init(color: .white.opacity(0.12), location: 1.0),
                                ]),
                                center: .center,
                                angle: .degrees(phase * 120)
                            )
                        )
                    
                    // 高光 — 左上
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.25
                            )
                        )
                        .frame(width: size * 0.4, height: size * 0.2)
                        .offset(x: -size * 0.12, y: -size * 0.18)
                        .rotationEffect(.degrees(15))
                        .blur(radius: 2)
                    
                    // 次高光 — 右下
                    Ellipse()
                        .fill(.white.opacity(0.08))
                        .frame(width: size * 0.25, height: size * 0.12)
                        .offset(x: size * 0.1, y: size * 0.15)
                        .blur(radius: 4)
                }
                .frame(width: size, height: size)
                .scaleEffect(
                    x: 1 + 0.04 * intensity * sin(phase * 2.5),
                    y: 1 + 0.04 * intensity * cos(phase * 2.3)
                )
                .shadow(color: Color(hue: phase.truncatingRemainder(dividingBy: 1), saturation: 0.8, brightness: 0.7).opacity(0.4 * intensity),
                        radius: size * 0.2, x: 0, y: 0)
            }
            .frame(width: size * 1.9, height: size * 1.9)
            .onReceive(timer) { _ in
                let speed = intensity > 0.5 ? 0.01 : 0.003
                withAnimation(.linear(duration: 0.033)) {
                    phase += speed
                }
            }
        }
    }
}

// MARK: - 独立律动球窗口（全局快捷键唤起时使用）
#Preview {
    DreamOrbView(size: 100, previewMode: true)
        .frame(width: 200, height: 200)
        .background(Color.black)
}
