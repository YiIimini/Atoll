# Claude CLI Spec for Atoll

## Project Overview
- **Project**: Atoll - DynamicIsland for macOS
- **Language**: Swift (SwiftUI)
- **Files**: 313 Swift files, ~98K lines
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
- `managers/`: Singleton managers (102 `.shared` singletons)
- `models/`: Data models and view models
- `services/`: Backend services
- The DynamicIsland group in pbxproj uses `PBXFileSystemSynchronizedRootGroup` (auto-discovery)

## File System
- Source files auto-discovered from `DynamicIsland/` directory
- Adding new Swift files to `DynamicIsland/` automatically includes them in the build
