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



struct Shortcuts: View {
    @Default(.enableTimerFeature) var enableTimerFeature
    @Default(.enableClipboardManager) var enableClipboardManager
    @Default(.enableShortcuts) var enableShortcuts
    @Default(.enableStatsFeature) var enableStatsFeature
    @Default(.enableColorPickerFeature) var enableColorPickerFeature

    private func highlightID(_ title: String) -> String {
        SettingsTab.shortcuts.highlightID(for: title)
    }

    var body: some View {
        Form {
            Section {
                Defaults.Toggle(key: .enableShortcuts) {
                    Text("Enable global keyboard shortcuts")
                }
                .settingsHighlight(id: highlightID("Enable global keyboard shortcuts"))
            } header: {
                Text("General")
            } footer: {
                Text("When disabled, all keyboard shortcuts will be inactive. You can still use the UI controls.")
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            if enableShortcuts {
                Section {
                    KeyboardShortcuts.Recorder("Toggle Sneak Peek:", name: .toggleSneakPeek)
                        .disabled(!enableShortcuts)
                } header: {
                    Text("Media")
                } footer: {
                    Text("Sneak Peek shows the media title and artist under the notch for a few seconds.")
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Section {
                    KeyboardShortcuts.Recorder("Toggle Notch Open:", name: .toggleNotchOpen)
                        .disabled(!enableShortcuts)
                } header: {
                    Text("Navigation")
                } footer: {
                    Text("Toggle the Dynamic Island open or closed from anywhere.")
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            KeyboardShortcuts.Recorder("Start Demo Timer:", name: .startDemoTimer)
                                .disabled(!enableShortcuts || !enableTimerFeature)
                            if !enableTimerFeature {
                                Text("Timer feature is disabled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                    }
                } header: {
                    Text("Timer")
                } footer: {
                    Text("Starts a 5-minute demo timer to test the timer live activity feature. Only works when timer feature is enabled.")
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            KeyboardShortcuts.Recorder("Clipboard History:", name: .clipboardHistoryPanel)
                                .disabled(!enableShortcuts || !enableClipboardManager)
                            if !enableClipboardManager {
                                Text("Clipboard feature is disabled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                    }
                } header: {
                    Text("Clipboard")
                } footer: {
                    Text("Opens the clipboard history panel. Default is Cmd+Shift+V (similar to Windows+V on PC). Only works when clipboard feature is enabled.")
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            KeyboardShortcuts.Recorder("Screen Assistant:", name: .screenAssistantPanel)
                                .disabled(!enableShortcuts || !Defaults[.enableScreenAssistant])
                            if !Defaults[.enableScreenAssistant] {
                                Text("Screen Assistant feature is disabled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                    }
                } header: {
                    Text("AI Assistant")
                } footer: {
                    Text("Opens the AI assistant panel for file analysis and conversation. Default is Cmd+Shift+A. Only works when screen assistant feature is enabled.")
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            KeyboardShortcuts.Recorder("Toggle Terminal Tab:", name: .toggleTerminalTab)
                                .disabled(!enableShortcuts || !Defaults[.enableTerminalFeature])
                            if !Defaults[.enableTerminalFeature] {
                                Text("Terminal feature is disabled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                    }
                } header: {
                    Text("Terminal")
                } footer: {
                    Text("Opens the terminal tab in the notch. Default is Ctrl+`. Only works when terminal feature is enabled.")
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            KeyboardShortcuts.Recorder("Color Picker Panel:", name: .colorPickerPanel)
                                .disabled(!enableShortcuts || !enableColorPickerFeature)
                            if !enableColorPickerFeature {
                                Text("Color Picker feature is disabled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                    }
                } header: {
                    Text("Color Picker")
                } footer: {
                    Text("Opens the color picker panel for screen color capture. Default is Cmd+Shift+P. Only works when color picker feature is enabled.")
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            } else {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keyboard shortcuts are disabled")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("Enable global keyboard shortcuts above to customize your shortcuts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Shortcuts")
    }
}
