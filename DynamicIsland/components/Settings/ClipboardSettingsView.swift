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



struct ClipboardSettings: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @Default(.enableClipboardManager) var enableClipboardManager
    @Default(.clipboardHistorySize) var clipboardHistorySize
    @Default(.showClipboardIcon) var showClipboardIcon
    @Default(.clipboardDisplayMode) var clipboardDisplayMode

    private func highlightID(_ title: String) -> String {
        SettingsTab.clipboard.highlightID(for: title)
    }

    var body: some View {
        Form {
            Section {
                Defaults.Toggle(key: .enableClipboardManager) {
                    Text("Enable Clipboard Manager")
                }
                .settingsHighlight(id: highlightID("Enable Clipboard Manager"))
                .onChange(of: enableClipboardManager) { _, enabled in
                    if enabled {
                        clipboardManager.startMonitoring()
                    } else {
                        clipboardManager.stopMonitoring()
                    }
                }
            } header: {
                Text("Clipboard Manager")
            } footer: {
                Text("Monitor clipboard changes and keep a history of recent copies. Use Cmd+Shift+V to quickly access clipboard history.")
            }

            if enableClipboardManager {
                Section {
                    Defaults.Toggle(key: .showClipboardIcon) {
                        Text("Show Clipboard Icon")
                    }
                    .settingsHighlight(id: highlightID("Show Clipboard Icon"))

                    HStack {
                        Text("Display Mode")
                        Spacer()
                        Picker("", selection: $clipboardDisplayMode) {
                            ForEach(ClipboardDisplayMode.allCases, id: \.self) { mode in
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
                        Picker("", selection: $clipboardHistorySize) {
                            Text("3 items").tag(3)
                            Text("5 items").tag(5)
                            Text("7 items").tag(7)
                            Text("10 items").tag(10)
                        }
                        .pickerStyle(.menu)
                        .frame(minWidth: 100)
                    }
                    .settingsHighlight(id: highlightID("History Size"))

                    HStack {
                        Text("Current Items")
                        Spacer()
                        Text("\(clipboardManager.clipboardHistory.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Pinned Items")
                        Spacer()
                        Text("\(clipboardManager.pinnedItems.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Monitoring Status")
                        Spacer()
                        Text(clipboardManager.isMonitoring ? "Active" : "Stopped")
                            .foregroundColor(clipboardManager.isMonitoring ? .green : .secondary)
                    }
                } header: {
                    Text("Settings")
                } footer: {
                    switch clipboardDisplayMode {
                    case .popover:
                        Text("Popover mode shows clipboard as a dropdown attached to the clipboard button.")
                    case .panel:
                        Text("Panel mode shows clipboard in a floating window near the notch.")
                    case .separateTab:
                        Text("Separate Tab mode integrates Copied Items and Notes into a single view. If both are enabled, Notes appear on the right and Clipboard on the left.")
                    }
                }

                Section {
                    Button("Clear Clipboard History") {
                        clipboardManager.clearHistory()
                    }
                    .foregroundColor(.red)
                    .disabled(clipboardManager.clipboardHistory.isEmpty)

                    Button("Clear Pinned Items") {
                        clipboardManager.pinnedItems.removeAll()
                        clipboardManager.savePinnedItemsToDefaults()
                    }
                    .foregroundColor(.red)
                    .disabled(clipboardManager.pinnedItems.isEmpty)
                } header: {
                    Text("Actions")
                } footer: {
                    Text("Clear clipboard history removes recent copies. Clear pinned items removes your favorites. Both actions are permanent.")
                }

                if !clipboardManager.clipboardHistory.isEmpty {
                    Section {
                        ForEach(clipboardManager.clipboardHistory) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: item.type.icon)
                                        .foregroundColor(.blue)
                                        .frame(width: 16)
                                    Text(item.type.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(timeAgoString(from: item.timestamp))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Text(item.preview)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text("Current History")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Clipboard")
        .onAppear {
            if enableClipboardManager && !clipboardManager.isMonitoring {
                clipboardManager.startMonitoring()
            }
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
