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



struct ColorPickerSettings: View {
    @ObservedObject var colorPickerManager = ColorPickerManager.shared
    @Default(.enableColorPickerFeature) var enableColorPickerFeature
    @Default(.showColorFormats) var showColorFormats
    @Default(.colorPickerDisplayMode) var colorPickerDisplayMode
    @Default(.colorHistorySize) var colorHistorySize
    @Default(.showColorPickerIcon) var showColorPickerIcon

    private func highlightID(_ title: String) -> String {
        SettingsTab.colorPicker.highlightID(for: title)
    }

    var body: some View {
        Form {
            Section {
                Defaults.Toggle(key: .enableColorPickerFeature) {
                    Text("Enable Color Picker")
                }
                .settingsHighlight(id: highlightID("Enable Color Picker"))
            } header: {
                Text("Color Picker")
            } footer: {
                Text("Enable screen color picking functionality. Use Cmd+Shift+P to quickly access the color picker.")
            }

            if enableColorPickerFeature {
                Section {
                    Defaults.Toggle(key: .showColorPickerIcon) {
                        Text("Show Color Picker Icon")
                    }
                    .settingsHighlight(id: highlightID("Show Color Picker Icon"))

                    HStack {
                        Text("Display Mode")
                        Spacer()
                        Picker("", selection: $colorPickerDisplayMode) {
                            ForEach(ColorPickerDisplayMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(minWidth: 100)
                    }
                    .settingsHighlight(id: highlightID("Display Mode"))

                    HStack {
                        Text("History Size")
                        Spacer()
                        Picker("", selection: $colorHistorySize) {
                            Text("5 colors").tag(5)
                            Text("10 colors").tag(10)
                            Text("15 colors").tag(15)
                            Text("20 colors").tag(20)
                        }
                        .pickerStyle(.menu)
                        .frame(minWidth: 100)
                    }
                    .settingsHighlight(id: highlightID("History Size"))

                    Defaults.Toggle(key: .showColorFormats) {
                        Text("Show All Color Formats")
                    }
                    .settingsHighlight(id: highlightID("Show All Color Formats"))

                } header: {
                    Text("Settings")
                } footer: {
                    switch colorPickerDisplayMode {
                    case .popover:
                        Text("Popover mode shows color picker as a dropdown attached to the color picker button. Panel mode shows color picker in a floating window.")
                    case .panel:
                        Text("Panel mode shows color picker in a floating window. Popover mode shows color picker as a dropdown attached to the color picker button.")
                    }
                }

                Section {
                    HStack {
                        Text("Color History")
                        Spacer()
                        Text("\(colorPickerManager.colorHistory.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Picking Status")
                        Spacer()
                        Text(colorPickerManager.isPickingColor ? "Active" : "Ready")
                            .foregroundColor(colorPickerManager.isPickingColor ? .green : .secondary)
                    }

                    Button("Show Color Picker Panel") {
                        ColorPickerPanelManager.shared.showColorPickerPanel()
                    }
                    .disabled(!enableColorPickerFeature)

                } header: {
                    Text("Status & Actions")
                }

                Section {
                    Button("Clear Color History") {
                        colorPickerManager.clearHistory()
                    }
                    .foregroundColor(.red)
                    .disabled(colorPickerManager.colorHistory.isEmpty)

                    Button("Start Color Picking") {
                        colorPickerManager.startColorPicking()
                    }
                    .disabled(!enableColorPickerFeature || colorPickerManager.isPickingColor)

                } header: {
                    Text("Quick Actions")
                } footer: {
                    Text("Clear color history removes all picked colors. Start color picking begins screen color capture mode.")
                }
            }
        }
        .navigationTitle("Color Picker")
    }
}
