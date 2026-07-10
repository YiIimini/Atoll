//
//  ScreenAssistantSettingsView.swift
//  DynamicIsland
//
//  Created by Richard Kunkli on 07/08/2024.
//
//  Refactored 2026-07-10: full multi-provider AI settings.
//
import Defaults
import SwiftUI

struct ScreenAssistantSettings: View {
    @ObservedObject var screenAssistantManager = ScreenAssistantManager.shared
    @Default(.enableScreenAssistant) var enableScreenAssistant
    @Default(.screenAssistantDisplayMode) var screenAssistantDisplayMode
    @Default(.selectedAIProvider) var selectedAIProvider
    @Default(.selectedAIModel) var selectedAIModel
    @Default(.enableThinkingMode) var enableThinkingMode
    @Default(.speechProvider) var speechProvider
    @Default(.speechApiKey) var speechApiKey
    @Default(.voiceMode) var voiceMode
    @Default(.localModelEndpoint) var localModelEndpoint

    // Per-provider API keys
    @Default(.geminiApiKey) var geminiApiKey
    @Default(.openaiApiKey) var openaiApiKey
    @Default(.claudeApiKey) var claudeApiKey
    @Default(.groqApiKey) var groqApiKey
    @Default(.deepseekApiKey) var deepseekApiKey
    @Default(.openrouterApiKey) var openrouterApiKey
    @Default(.qwenApiKey) var qwenApiKey
    @Default(.moonshotApiKey) var moonshotApiKey
    @Default(.zhipuApiKey) var zhipuApiKey
    @Default(.baichuanApiKey) var baichuanApiKey
    @Default(.yiApiKey) var yiApiKey
    @Default(.minimaxApiKey) var minimaxApiKey

    @State private var editingKeyFor: AIModelProvider? = nil
    @State private var editingKeyText = ""

    private func highlightID(_ title: String) -> String {
        SettingsTab.screenAssistant.highlightID(for: title)
    }

    var body: some View {
        Form {
            // MARK: - Enable toggle
            Section {
                Defaults.Toggle(key: .enableScreenAssistant) {
                    Text("Enable Screen Assistant")
                }
                .settingsHighlight(id: highlightID("Enable Screen Assistant"))
            } header: {
                Text("AI Assistant")
            } footer: {
                Text("AI-powered assistant that can analyze files, images, and provide conversational help. Use Cmd+Shift+A to quickly access the assistant.")
            }

            if enableScreenAssistant {

            // MARK: - Provider Selection
            Section {
                Picker("AI Provider", selection: $selectedAIProvider) {
                    ForEach(AIModelProvider.allCases) { provider in
                        HStack(spacing: 6) {
                            providerIcon(for: provider)
                            Text(provider.displayName)
                        }
                        .tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .settingsHighlight(id: highlightID("AI Provider"))
                .onChange(of: selectedAIProvider) { _, newProvider in
                    // Auto-select first model of new provider
                    if let firstModel = newProvider.supportedModels.first {
                        selectedAIModel = firstModel
                        enableThinkingMode = false
                    }
                }

                Text(selectedAIProvider.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Provider")
            }

            // MARK: - API Key
            Section {
                providerAPIKeyRow
            } header: {
                Text("API Key")
            } footer: {
                apiKeyFooterText
            }

            // MARK: - Model Selection
            Section {
                if selectedAIProvider.supportedModels.isEmpty {
                    Text("No models available")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Model", selection: $selectedAIModel) {
                        ForEach(selectedAIProvider.supportedModels) { model in
                            Text(model.name)
                                .tag(Optional(model))
                        }
                    }
                    .pickerStyle(.menu)
                    .settingsHighlight(id: highlightID("Model"))

                    if let currentModel = selectedAIModel, currentModel.supportsThinking {
                        Defaults.Toggle(key: .enableThinkingMode) {
                            HStack(spacing: 6) {
                                Text("Thinking Mode")
                                customBadge(text: "Beta")
                            }
                        }
                        .settingsHighlight(id: highlightID("Thinking Mode"))
                        .help("Enables extended reasoning / chain-of-thought for models that support it.")
                    }
                }
            } header: {
                Text("Model")
            } footer: {
                if let currentModel = selectedAIModel {
                    Text("Model ID: \(currentModel.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
            }

            // MARK: - Local Model Endpoint
            if selectedAIProvider == .local {
                Section {
                    TextField("http://localhost:11434", text: $localModelEndpoint)
                        .textFieldStyle(.roundedBorder)
                        .settingsHighlight(id: highlightID("Local Endpoint"))
                } header: {
                    Text("Local Endpoint")
                } footer: {
                    Text("Default Ollama API endpoint. Change if your local LLM server runs on a different address.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - 语音设置
            Section {
                Picker("语音识别引擎", selection: $speechProvider) {
                    ForEach(SpeechProvider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .settingsHighlight(id: highlightID("Speech Provider"))

                if speechProvider.needsApiKey {
                    HStack {
                        Text("API Key")
                        Spacer()
                        SecureField("输入 API Key", text: $speechApiKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                    .settingsHighlight(id: highlightID("Speech API Key"))
                }

                Picker("对话模式", selection: $voiceMode) {
                    ForEach(VoiceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .settingsHighlight(id: highlightID("Voice Mode"))
            } header: {
                Text("语音对话")
            } footer: {
                if speechProvider == .system {
                    Text("使用 macOS 内置语音识别，无需额外配置。\n「实时对话」模式下，说话会自动转为文字并在停顿 1.5 秒后自动发送，AI 回复会自动朗读。")
                        .foregroundStyle(.secondary).font(.caption)
                } else if speechProvider == .openaiWhisper {
                    Text("使用 OpenAI Whisper API 进行语音识别。需填写 API Key（与 ChatGPT Key 相同）。\n实时对话模式使用流式上传，每 3 秒识别一次。")
                        .foregroundStyle(.secondary).font(.caption)
                }
            }

            // MARK: - Display Mode
            Section {
                Picker("Display Mode", selection: $screenAssistantDisplayMode) {
                    ForEach(ScreenAssistantDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .settingsHighlight(id: highlightID("Display Mode"))
            } header: {
                Text("Display")
            } footer: {
                switch screenAssistantDisplayMode {
                case .popover:
                    Text("Popover mode shows the assistant as a dropdown attached to the AI button.")
                case .panel:
                    Text("Panel mode shows the assistant in a floating window near the notch.")
                }
            }

            // MARK: - Status
            Section {
                HStack {
                    Text("Attached Files")
                    Spacer()
                    Text("\(screenAssistantManager.attachedFiles.count)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Recording Status")
                    Spacer()
                    Text(screenAssistantManager.isRecording ? "Recording" : "Ready")
                        .foregroundColor(screenAssistantManager.isRecording ? .red : .secondary)
                }
            } header: {
                Text("Status")
            }

            // MARK: - Actions
            Section {
                Button("Clear All Files") {
                    screenAssistantManager.clearAllFiles()
                }
                .foregroundColor(.red)
                .disabled(screenAssistantManager.attachedFiles.isEmpty)
            } header: {
                Text("Actions")
            } footer: {
                Text("Clear all files removes all attached files and audio recordings. This action is permanent.")
            }

            // MARK: - Attached Files List
            if !screenAssistantManager.attachedFiles.isEmpty {
                Section {
                    ForEach(screenAssistantManager.attachedFiles) { file in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: file.type.iconName)
                                    .foregroundColor(.blue)
                                    .frame(width: 16)
                                Text(file.type.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(timeAgoString(from: file.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Text(file.name)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(2)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Attached Files")
                }
            }
        }

        }
        .formStyle(.grouped)
        .navigationTitle("Screen Assistant")
        .sheet(item: $editingKeyFor) { provider in
            apiKeyEditorSheet(for: provider)
        }
    }

    // MARK: - API Key Row

    @ViewBuilder
    private var providerAPIKeyRow: some View {
        let key = currentProviderKeyBinding
        let hasKey = !key.wrappedValue.isEmpty

        HStack {
            Text(selectedAIProvider.displayName + " API Key")
            Spacer()
            if hasKey {
                Text("••••••••")
                    .foregroundColor(.green)
            } else {
                Text("Not Set")
                    .foregroundColor(.red)
            }

            Button(hasKey ? "Change" : "Set") {
                editingKeyText = key.wrappedValue
                editingKeyFor = selectedAIProvider
            }
        }
    }

    private var currentProviderKeyBinding: Binding<String> {
        switch selectedAIProvider {
        case .gemini:     return $geminiApiKey
        case .openai:     return $openaiApiKey
        case .claude:     return $claudeApiKey
        case .local:      return .constant("")  // Local models don't need API keys
        case .groq:       return $groqApiKey
        case .deepseek:   return $deepseekApiKey
        case .openrouter: return $openrouterApiKey
        case .qwen:     return $qwenApiKey
        case .moonshot: return $moonshotApiKey
        case .zhipu:    return $zhipuApiKey
        case .baichuan: return $baichuanApiKey
        case .yi:       return $yiApiKey
        case .minimax:  return $minimaxApiKey
        }
    }

    // MARK: - API Key Editor Sheet

    @ViewBuilder
    private func apiKeyEditorSheet(for provider: AIModelProvider) -> some View {
        let binding = apiKeyBinding(for: provider)

        VStack(spacing: 20) {
            Text("\(provider.displayName) API Key")
                .font(.title2)
                .fontWeight(.semibold)

            providerGetKeyLink(for: provider)
                .font(.caption)

            SecureField("Enter API key", text: $editingKeyText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 340)

            HStack(spacing: 12) {
                Button("Cancel") {
                    editingKeyFor = nil
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    binding.wrappedValue = editingKeyText.trimmingCharacters(in: .whitespacesAndNewlines)
                    editingKeyFor = nil
                }
                .keyboardShortcut(.return)
                .disabled(editingKeyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private func apiKeyBinding(for provider: AIModelProvider) -> Binding<String> {
        switch provider {
        case .gemini:     return $geminiApiKey
        case .openai:     return $openaiApiKey
        case .claude:     return $claudeApiKey
        case .groq:       return $groqApiKey
        case .deepseek:   return $deepseekApiKey
        case .openrouter: return $openrouterApiKey
        case .qwen:     return $qwenApiKey
        case .moonshot: return $moonshotApiKey
        case .zhipu:    return $zhipuApiKey
        case .baichuan: return $baichuanApiKey
        case .yi:       return $yiApiKey
        case .minimax:  return $minimaxApiKey
        case .local:      return .constant("")
        }
    }

    @ViewBuilder
    private func providerGetKeyLink(for provider: AIModelProvider) -> some View {
        switch provider {
        case .gemini:
            Link("Get API key → Google AI Studio",
                 destination: URL(string: "https://aistudio.google.com/app/apikey")!)
        case .openai:
            Link("Get API key → OpenAI Platform",
                 destination: URL(string: "https://platform.openai.com/api-keys")!)
        case .claude:
            Link("Get API key → Anthropic Console",
                 destination: URL(string: "https://console.anthropic.com/settings/keys")!)
        case .groq:
            Link("Get API key → Groq Console",
                 destination: URL(string: "https://console.groq.com/keys")!)
        case .deepseek:
            Link("Get API key → DeepSeek Platform",
                 destination: URL(string: "https://platform.deepseek.com/api_keys")!)
        case .openrouter:
            Link("Get API key → OpenRouter Keys",
                 destination: URL(string: "https://openrouter.ai/keys")!)
        case .qwen:
            Link("获取 API Key → 阿里云百炼",
                 destination: URL(string: "https://bailian.console.aliyun.com/")!)
        case .moonshot:
            Link("获取 API Key → 月之暗面开放平台",
                 destination: URL(string: "https://platform.moonshot.cn/")!)
        case .zhipu:
            Link("获取 API Key → 智谱开放平台",
                 destination: URL(string: "https://open.bigmodel.cn/")!)
        case .baichuan:
            Link("获取 API Key → 百川智能开放平台",
                 destination: URL(string: "https://platform.baichuan-ai.com/")!)
        case .yi:
            Link("获取 API Key → 零一万物开放平台",
                 destination: URL(string: "https://platform.lingyiwanwu.com/")!)
        case .minimax:
            Link("获取 API Key → Minimax 开放平台",
                 destination: URL(string: "https://platform.minimax.chat/")!)
        case .local:
            EmptyView()
        }
    }

    // MARK: - Provider Icon

    @ViewBuilder
    private func providerIcon(for provider: AIModelProvider) -> some View {
        let name: String = {
            switch provider {
            case .gemini:     return "sparkles"
            case .openai:     return "cpu"
            case .claude:     return "message"
            case .local:      return "desktopcomputer"
            case .groq:       return "bolt"
            case .deepseek:   return "waveform"
            case .openrouter: return "globe"
            case .qwen:     return "text.bubble"
            case .moonshot: return "moon.stars"
            case .zhipu:    return "brain.head.profile"
            case .baichuan: return "scroll"
            case .yi:       return "sparkle.magnifyingglass"
            case .minimax:  return "waveform.and.mic"
            }
        }()
        Image(systemName: name)
            .font(.system(size: 12, weight: .semibold))
            .frame(width: 20, height: 20)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(providerTint(for: provider))
            )
    }

    private func providerTint(for provider: AIModelProvider) -> Color {
        switch provider {
        case .gemini:     return .blue
        case .openai:     return .green
        case .claude:     return .orange
        case .local:      return .gray
        case .groq:       return .purple
        case .deepseek:   return .teal
        case .openrouter: return .indigo
        case .qwen:     return .cyan
        case .moonshot: return .mint
        case .zhipu:    return .pink
        case .baichuan: return .red
        case .yi:       return .yellow
        case .minimax:  return .indigo
        }
    }

    // MARK: - Footer text per provider

    private var apiKeyFooterText: Text {
        if currentProviderKeyBinding.wrappedValue.isEmpty {
            return Text("Required to use \(selectedAIProvider.displayName). Your key is stored securely in the macOS Keychain via UserDefaults.")
                .foregroundStyle(.secondary)
                .font(.caption)
        } else {
            return Text("API key configured. Change it if needed.")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
