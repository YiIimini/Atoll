//
//  SettingsView.swift
//  DynamicIsland
//
//  Created by Richard Kunkli on 07/08/2024.
//
import AppKit
import AVFoundation
import Combine
import Defaults
import EventKit
import KeyboardShortcuts
import LaunchAtLogin
import LottieUI
import Sparkle
import SwiftUI
import SwiftUIIntrospect
import UniformTypeIdentifiers

/// Groups for organizing settings tabs in the sidebar.
private enum SettingsTabGroup: String, CaseIterable, Identifiable {
    case core
    case mediaAndDisplay
    case system
    case productivity
    case utilities
    case developer
    case integrations
    case info

    var id: String { rawValue }

    /// Display title for the section header.  `nil` means no visible header.
    var title: String? {
        switch self {
        case .core:             return nil
        case .mediaAndDisplay:  return String(localized: "Media & Display")
        case .system:           return String(localized: "System")
        case .productivity:     return String(localized: "Productivity")
        case .utilities:        return String(localized: "Utilities")
        case .developer:        return String(localized: "Developer")
        case .integrations:     return String(localized: "Integrations")
        case .info:             return nil
        }
    }
}

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case liveActivities
    case appearance
    case lockScreen
    case media
    case devices
    case extensions
    case timer
    case calendar
    case hudAndOSD
    case battery
    case stats
    case clipboard
    case screenAssistant
    case colorPicker
    case downloads
    case shelf
    case shortcuts
    case notes
    case terminal
    case about

    var id: String { rawValue }

    /// Which sidebar group this tab belongs to.
    var group: SettingsTabGroup {
        switch self {
        case .general, .appearance:                                          return .core
        case .media, .liveActivities, .lockScreen, .devices:                 return .mediaAndDisplay
        case .hudAndOSD, .battery:                                           return .system
        case .timer, .calendar, .notes:                                      return .productivity
        case .clipboard, .screenAssistant, .colorPicker, .shelf,
             .downloads, .shortcuts:                                         return .utilities
        case .stats, .terminal:                                              return .developer
        case .extensions:                                                    return .integrations
        case .about:                                                         return .info
        }
    }

    var title: String {
        switch self {
        case .general: return String(localized: "General")
        case .liveActivities: return String(localized: "Live Activities")
        case .appearance: return String(localized: "Appearance")
        case .lockScreen: return String(localized: "Lock Screen")
        case .media: return String(localized: "Media")
        case .devices: return String(localized: "Devices")
        case .extensions: return String(localized: "Extensions")
        case .timer: return String(localized: "Timer")
        case .calendar: return String(localized: "Calendar")
        case .hudAndOSD: return String(localized: "Controls")
        case .battery: return String(localized: "Battery")
        case .stats: return String(localized: "Stats")
        case .clipboard: return String(localized: "Clipboard")
        case .screenAssistant: return String(localized: "Screen Assistant")
        case .colorPicker: return String(localized: "Color Picker")
        case .downloads: return String(localized: "Downloads")
        case .shelf: return String(localized: "Shelf")
        case .shortcuts: return String(localized: "Shortcuts")
        case .notes: return String(localized: "Notes")
        case .terminal: return String(localized: "Terminal")
        case .about: return String(localized: "About")
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "gear"
        case .liveActivities: return "waveform.path.ecg"
        case .appearance: return "paintpalette"
        case .lockScreen: return "lock.laptopcomputer"
        case .media: return "play.laptopcomputer"
        case .devices: return "headphones"
        case .extensions: return "puzzlepiece.extension"
        case .timer: return "timer"
        case .calendar: return "calendar"
        case .hudAndOSD: return "dial.medium.fill"
        case .battery: return "battery.100.bolt"
        case .stats: return "chart.xyaxis.line"
        case .clipboard: return "clipboard"
        case .screenAssistant: return "brain.head.profile"
        case .colorPicker: return "eyedropper"
        case .downloads: return "square.and.arrow.down"
        case .shelf: return "books.vertical"
        case .shortcuts: return "keyboard"
        case .notes: return "note.text"
        case .terminal: return "apple.terminal"
        case .about: return "info.circle"
        }
    }

    var tint: Color {
        switch self {
        case .general: return .blue
        case .liveActivities: return .pink
        case .appearance: return .purple
        case .lockScreen: return .orange
        case .media: return .green
        case .devices: return Color(red: 0.1, green: 0.11, blue: 0.12)
        case .extensions: return Color(red: 0.557, green: 0.353, blue: 0.957)
        case .timer: return .red
        case .calendar: return .cyan
        case .hudAndOSD: return .indigo
        case .battery: return Color(red: 0.202, green: 0.783, blue: 0.348, opacity: 1.000)
        case .stats: return .teal
        case .clipboard: return .mint
        case .screenAssistant: return .pink
        case .colorPicker: return .accentColor
        case .downloads: return .gray
        case .shelf: return .brown
        case .shortcuts: return .orange
        case .notes: return Color(red: 0.979, green: 0.716, blue: 0.153, opacity: 1.000)
        case .terminal: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .about: return .secondary
        }
    }

    func highlightID(for title: String) -> String {
        "\(rawValue)-\(title)"
    }
}



struct TerminalSettings: View {
    @ObservedObject var terminalManager = TerminalManager.shared
    @Default(.enableTerminalFeature) var enableTerminalFeature
    @Default(.terminalShellPath) var terminalShellPath
    @Default(.terminalFontFamily) var terminalFontFamily
    @Default(.terminalFontSize) var terminalFontSize
    @Default(.terminalOpacity) var terminalOpacity
    @Default(.terminalMaxHeightFraction) var terminalMaxHeightFraction
    @Default(.terminalCursorStyle) var terminalCursorStyle
    @Default(.terminalScrollbackLines) var terminalScrollbackLines
    @Default(.terminalOptionAsMeta) var terminalOptionAsMeta
    @Default(.terminalMouseReporting) var terminalMouseReporting
    @Default(.terminalBoldAsBright) var terminalBoldAsBright
    @Default(.terminalBackgroundColor) var terminalBackgroundColor
    @Default(.terminalForegroundColor) var terminalForegroundColor
    @Default(.terminalCursorColor) var terminalCursorColor

    private func highlightID(_ title: String) -> String {
        SettingsTab.terminal.highlightID(for: title)
    }

    private var formattedMaxHeight: String {
        "\(Int(terminalMaxHeightFraction * 100))% of screen"
    }

    /// All monospaced font families available on the system.
    private var monospacedFontFamilies: [String] {
        NSFontManager.shared.availableFontFamilies.filter { family in
            guard let font = NSFont(name: family, size: 12) else { return false }
            return font.isFixedPitch
                || font.fontDescriptor.symbolicTraits.contains(.monoSpace)
        }
        .sorted()
    }

    /// Display name for the font picker — shows "System Monospaced" when no custom font is set.
    private var fontDisplayName: String {
        terminalFontFamily.isEmpty ? "System Monospaced" : terminalFontFamily
    }

    private var cursorStyleBinding: Binding<TerminalCursorStyleOption> {
        Binding(
            get: { TerminalCursorStyleOption(rawValue: terminalCursorStyle) ?? .blinkBlock },
            set: { terminalCursorStyle = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section {
                Defaults.Toggle(key: .enableTerminalFeature) {
                    Text("Enable terminal")
                }
                .settingsHighlight(id: highlightID("Enable terminal"))

                if enableTerminalFeature {
                    Defaults.Toggle(key: .terminalStickyMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Keep terminal open until clicked outside")
                            Text("Prevents the terminal from closing when the cursor accidentally leaves the notch area.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .settingsHighlight(id: highlightID("Keep terminal open"))
                }
            } header: {
                Text("General")
            } footer: {
                Text("Adds a Guake-style dropdown terminal tab. The terminal session persists across notch open/close cycles.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if enableTerminalFeature {
                // MARK: Shell
                Section {
                    HStack {
                        Text("Shell path")
                        Spacer()
                        TextField("", text: $terminalShellPath)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                            .multilineTextAlignment(.trailing)
                    }
                    .settingsHighlight(id: highlightID("Shell path"))
                } header: {
                    Text("Shell")
                }

                // MARK: Appearance
                Section {
                    Picker("Font family", selection: $terminalFontFamily) {
                        Text("System Monospaced").tag("")
                        Divider()
                        ForEach(monospacedFontFamilies, id: \.self) { family in
                            Text(family)
                                .font(.custom(family, size: 13))
                                .tag(family)
                        }
                    }
                    .onChange(of: terminalFontFamily) { _, newValue in
                        terminalManager.applyFontFamily(newValue)
                    }
                    .settingsHighlight(id: highlightID("Font family"))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Font size")
                            Spacer()
                            Text("\(Int(terminalFontSize)) pt")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $terminalFontSize, in: 8...24, step: 1)
                            .onChange(of: terminalFontSize) { _, newValue in
                                terminalManager.applyFontSize(newValue)
                            }
                    }
                    .settingsHighlight(id: highlightID("Font size"))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Terminal opacity")
                            Spacer()
                            Text("\(Int(terminalOpacity * 100))%")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $terminalOpacity, in: 0.3...1.0, step: 0.05)
                            .onChange(of: terminalOpacity) { _, newValue in
                                terminalManager.applyOpacity(newValue)
                            }
                    }
                    .settingsHighlight(id: highlightID("Terminal opacity"))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Maximum height")
                            Spacer()
                            Text(formattedMaxHeight)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $terminalMaxHeightFraction, in: 0.2...0.5, step: 0.05)
                    }
                    .settingsHighlight(id: highlightID("Maximum height"))
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Terminal opacity only affects the terminal backdrop; text stays fully opaque. Blur uses the system material behind the window.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: Colors
                Section {
                    ColorPicker("Background", selection: $terminalBackgroundColor, supportsOpacity: false)
                        .onChange(of: terminalBackgroundColor) { _, newValue in
                            terminalManager.applyBackgroundColor(newValue)
                        }
                        .settingsHighlight(id: highlightID("Background color"))

                    ColorPicker("Foreground", selection: $terminalForegroundColor, supportsOpacity: false)
                        .onChange(of: terminalForegroundColor) { _, newValue in
                            terminalManager.applyForegroundColor(newValue)
                        }
                        .settingsHighlight(id: highlightID("Foreground color"))

                    ColorPicker("Cursor", selection: $terminalCursorColor, supportsOpacity: false)
                        .onChange(of: terminalCursorColor) { _, newValue in
                            terminalManager.applyCursorColor(newValue)
                        }
                        .settingsHighlight(id: highlightID("Cursor color"))

                    Toggle("Bold text as bright colors", isOn: $terminalBoldAsBright)
                        .onChange(of: terminalBoldAsBright) { _, newValue in
                            terminalManager.applyBoldAsBright(newValue)
                        }
                        .settingsHighlight(id: highlightID("Bold as bright"))
                } header: {
                    Text("Colors")
                } footer: {
                    Text("When bold-as-bright is off, bold text uses a heavier font weight instead of bright ANSI colors.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: Cursor
                Section {
                    Picker("Cursor style", selection: cursorStyleBinding) {
                        ForEach(TerminalCursorStyleOption.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .onChange(of: terminalCursorStyle) { _, newValue in
                        if let style = TerminalCursorStyleOption(rawValue: newValue) {
                            terminalManager.applyCursorStyle(style)
                        }
                    }
                    .settingsHighlight(id: highlightID("Cursor style"))
                } header: {
                    Text("Cursor")
                }

                // MARK: Scrollback
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Scrollback lines")
                            Spacer()
                            Text("\(terminalScrollbackLines)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(
                            value: Binding(
                                get: { Double(terminalScrollbackLines) },
                                set: { terminalScrollbackLines = Int($0) }
                            ),
                            in: 100...10000,
                            step: 100
                        )
                        .onChange(of: terminalScrollbackLines) { _, newValue in
                            terminalManager.applyScrollback(newValue)
                        }
                    }
                    .settingsHighlight(id: highlightID("Scrollback lines"))
                } header: {
                    Text("Scrollback")
                } footer: {
                    Text("Number of lines kept in the scrollback buffer. Higher values use more memory.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: Input
                Section {
                    Toggle("Option as Meta key", isOn: $terminalOptionAsMeta)
                        .onChange(of: terminalOptionAsMeta) { _, newValue in
                            terminalManager.applyOptionAsMeta(newValue)
                        }
                        .settingsHighlight(id: highlightID("Option as Meta"))

                    Toggle("Allow mouse reporting", isOn: $terminalMouseReporting)
                        .onChange(of: terminalMouseReporting) { _, newValue in
                            terminalManager.applyMouseReporting(newValue)
                        }
                        .settingsHighlight(id: highlightID("Mouse reporting"))
                } header: {
                    Text("Input")
                } footer: {
                    Text("Option as Meta sends Esc+key instead of macOS special characters. Mouse reporting forwards mouse events to terminal applications like vim or tmux.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: Actions
                Section {
                    Button("Restart Shell") {
                        terminalManager.restartShell()
                    }
                    .disabled(!terminalManager.isProcessRunning)
                } header: {
                    Text("Actions")
                } footer: {
                    Text("Restarts the shell process. Any unsaved work in the terminal will be lost.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Terminal")
    }
}

// MARK: - Reusable App Icon View

/// Fetches the real app icon from the system using bundle identifiers,
/// falling back to an asset catalog image or an SF Symbol.
