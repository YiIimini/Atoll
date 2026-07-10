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



struct NotesSettingsView: View {
    @EnvironmentObject var vm: DynamicIslandViewModel
    @ObservedObject var coordinator = DynamicIslandViewCoordinator.shared
    @ObservedObject private var appleNotesSync = AppleNotesSyncManager.shared
    @Default(.enableNotes) private var enableNotes
    @Default(.enableAppleNotesSync) private var enableAppleNotesSync
    @Default(.appleNotesLastSyncDate) private var appleNotesLastSyncDate

    private func highlightID(_ title: String) -> String {
        SettingsTab.notes.highlightID(for: title)
    }

    var body: some View {
        Form {
            Section {
                Defaults.Toggle(key: .enableNotes) {
                    Text("Enable Notes")
                }
                if enableNotes {
                    Defaults.Toggle(key: .enableNotePinning) {
                        Text("Enable Note Pinning")
                    }
                    Defaults.Toggle(key: .enableNoteSearch) {
                        Text("Enable Note Search")
                    }
                    Defaults.Toggle(key: .enableNoteColorFiltering) {
                        Text("Enable Color Filtering")
                    }
                    Defaults.Toggle(key: .enableCreateFromClipboard) {
                        Text("Enable Create from Clipboard")
                    }
                    Defaults.Toggle(key: .enableNoteCharCount) {
                        Text("Show Character Count")
                    }
                }
            } header: {
                Text("General")
            } footer: {
                Text("Customize how you organize and create notes. Enabling color filtering and search helps manage large lists.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if enableNotes {
                Section {
                    Defaults.Toggle(key: .enableAppleNotesSync) {
                        Text("Sync with Apple Notes")
                    }
                    .settingsHighlight(id: highlightID("Sync with Apple Notes"))

                    if enableAppleNotesSync {
                        Button {
                            Task {
                                let notes = Defaults[.savedNotes]
                                if let merged = await appleNotesSync.sync(localNotes: notes) {
                                    Defaults[.savedNotes] = merged
                                }
                            }
                        } label: {
                            HStack {
                                Text("Sync Now")
                                Spacer()
                                if appleNotesSync.isSyncing {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                            }
                        }
                        .disabled(appleNotesSync.isSyncing)
                        .settingsHighlight(id: highlightID("Sync Now"))

                        if let lastSync = appleNotesLastSyncDate {
                            LabeledContent("Last synced") {
                                Text(lastSync, style: .relative)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let error = appleNotesSync.lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Apple Notes")
                } footer: {
                    Text("Two-way sync with the macOS Notes app. Notes created in Atoll appear in the Atoll folder in Notes, and your existing Apple Notes are imported into the notch. Grant Automation permission for Notes when prompted.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Notes")
    }
}

// MARK: - Terminal Settings
