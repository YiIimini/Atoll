# Claude CLI Spec for Atoll

## Project Overview
- **Project**: Atoll - DynamicIsland for macOS
- **Language**: Swift (SwiftUI)
- **Files**: 313+ Swift files, ~98K lines
- **Build**: Xcode project `DynamicIsland.xcodeproj`
- **Source**: `DynamicIsland/` directory
- **Package Manager**: Swift Package Manager (dependencies in pbxproj)

## Key Dependencies
- Defaults (user defaults wrapper)
- Sparkle (auto-update)
- KeyboardShortcuts
- LottieUI
- SwiftUIIntrospect
- SkyLightWindow (private framework)
- MacroVisionKit (private framework)
- Collections
- LaunchAtLogin
- SwiftTerm

## Architecture Notes
- `DynamicIslandApp.swift` (1,596 lines): App entry point, AppDelegate, window management
- `ContentView.swift` (2,979 lines): Main content coordinator
- `components/`: UI components organized by feature
- `components/Settings/`: Settings UI — 27 files, organized by SettingsTab enum (22 tabs across 7 groups)
- `managers/`: Singleton managers (102 `.shared` singletons)
- `models/`: Data models and view models (`Constants.swift` contains ~180 `Defaults.Keys` and all enums)
- `services/`: Backend services
- The DynamicIsland group in pbxproj uses `PBXFileSystemSynchronizedRootGroup` (auto-discovery)

## Settings Structure (as of 2026-07-10)
Settings are defined via `SettingsTab` enum in `SettingsView.swift`, organized into `SettingsTabGroup`:

| Group | Tabs |
|---|---|
| Core | General, Appearance |
| Media & Display | Media, Live Activities, Lock Screen, Devices |
| System | Controls (HUD/OSD), Battery |
| Productivity | Timer, Calendar, Notes |
| Utilities | Clipboard, Screen Assistant, Color Picker, Shelf, Downloads, Shortcuts |
| Developer | Stats, Terminal |
| Integrations | Extensions |
| Info | About |

## AI / Screen Assistant
- **Provider enum**: `AIModelProvider` in `Constants.swift` (line 647) — 7 providers: Gemini, OpenAI GPT, Claude, Groq, DeepSeek, OpenRouter, Local
- **Model struct**: `AIModel` (line 735) — `Codable, Identifiable, Defaults.Serializable, Hashable`
- **API keys**: Per-provider keys in `Defaults.Keys` (`geminiApiKey`, `openaiApiKey`, `claudeApiKey`, `groqApiKey`, `deepseekApiKey`, `openrouterApiKey`)
- **Settings UI**: `ScreenAssistantSettingsView.swift` (~400 lines) — provider picker, API key sheet editor, model selection, thinking mode toggle, local endpoint
- **Manager**: `ScreenAssistantManager.swift` — routes to `sendToGeminiAPI/sendToOpenAIAPI/sendToClaudeAPI/sendToLocalAPI/sendToGroqAPI/sendToDeepSeekAPI/sendToOpenRouterAPI`, all reuse `performOpenAIRequest`
- All `switch provider` statements must cover all 7 cases exhaustively

## File System
- Source files auto-discovered from `DynamicIsland/` directory
- Adding new Swift files to `DynamicIsland/` automatically includes them in the build
- New Settings tabs: add enum case to `SettingsTab`, assign group, create `*SettingsView.swift` in `components/Settings/`, wire in `detailView(for:)` 

## Defaults Keys
All configuration keys are defined in `DynamicIsland/models/Constants.swift` under `extension Defaults.Keys` (starting at line 848). Every key exposed in Settings UI must have a corresponding `@Default` read in its Settings view file. Use `grep -r "KeyName" DynamicIsland/components/Settings/` to verify UI coverage.
