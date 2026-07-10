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



struct Charge: View {
    @ObservedObject private var batteryStatusViewModel = BatteryStatusViewModel.shared
    @Default(.showPowerStatusNotifications) private var showPowerStatusNotifications
    @Default(.showChargingBatteryHUD) private var showChargingBatteryHUD
    @Default(.showLowBatteryHUD) private var showLowBatteryHUD
    @Default(.showFullBatteryHUD) private var showFullBatteryHUD
    @Default(.chargingBatteryHUDDuration) private var chargingBatteryHUDDuration
    @Default(.lowBatteryHUDDuration) private var lowBatteryHUDDuration
    @Default(.fullBatteryHUDDuration) private var fullBatteryHUDDuration
    @Default(.lowBatteryHUDThreshold) private var lowBatteryHUDThreshold
    @Default(.fullBatteryHUDThreshold) private var fullBatteryHUDThreshold
    @Default(.lowBatteryHUDStyle) private var lowBatteryHUDStyle
    @Default(.fullBatteryHUDStyle) private var fullBatteryHUDStyle

    private func highlightID(_ title: String) -> String {
        SettingsTab.battery.highlightID(for: title)
    }

    private var chargingDurationBinding: Binding<Double> {
        Binding(
            get: { Double(chargingBatteryHUDDuration) },
            set: { chargingBatteryHUDDuration = Int($0.rounded()) }
        )
    }

    private var lowBatteryDurationBinding: Binding<Double> {
        Binding(
            get: { Double(lowBatteryHUDDuration) },
            set: { lowBatteryHUDDuration = Int($0.rounded()) }
        )
    }

    private var fullBatteryDurationBinding: Binding<Double> {
        Binding(
            get: { Double(fullBatteryHUDDuration) },
            set: { fullBatteryHUDDuration = Int($0.rounded()) }
        )
    }

    private var lowBatteryThresholdBinding: Binding<Double> {
        Binding(
            get: { Double(lowBatteryHUDThreshold) },
            set: { lowBatteryHUDThreshold = Int($0.rounded()) }
        )
    }

    private var fullBatteryThresholdBinding: Binding<Double> {
        Binding(
            get: { Double(fullBatteryHUDThreshold) },
            set: { fullBatteryHUDThreshold = Int($0.rounded()) }
        )
    }

    private func sectionOpacity(_ isEnabled: Bool) -> Double {
        isEnabled ? 1 : 0.5
    }

    var body: some View {
        Form {
            if BatteryActivityManager.shared.hasBattery() {
                Section {
                    Defaults.Toggle(key: .showBatteryIndicator) {
                        Text("Show battery indicator")
                    }
                    .settingsHighlight(id: highlightID("Show battery indicator"))
                    Defaults.Toggle(key: .showPowerStatusNotifications) {
                        Text("Show power status notifications")
                    }
                    .settingsHighlight(id: highlightID("Show power status notifications"))
                    Defaults.Toggle(key: .playLowBatteryAlertSound) {
                        Text("Play low battery alert sound")
                    }
                    .settingsHighlight(id: highlightID("Play low battery alert sound"))
                } header: {
                    Text("General")
                }
                Section {
                    Defaults.Toggle(key: .showBatteryPercentage) {
                        Text("Show battery percentage")
                    }
                    .settingsHighlight(id: highlightID("Show battery percentage"))
                    Defaults.Toggle(key: .showPowerStatusIcons) {
                        Text("Show power status icons")
                    }
                    .settingsHighlight(id: highlightID("Show power status icons"))
                } header: {
                    Text("Battery Information")
                }
                Section {
                    Defaults.Toggle(key: .showChargingBatteryHUD) {
                        Text("Charging HUD")
                    }
                    .settingsHighlight(id: highlightID("Charging HUD"))

                    Defaults.Toggle(key: .showLowBatteryHUD) {
                        Text("Low battery HUD")
                    }
                    .settingsHighlight(id: highlightID("Low battery HUD"))

                    Defaults.Toggle(key: .showFullBatteryHUD) {
                        Text("Fully charged HUD")
                    }
                    .settingsHighlight(id: highlightID("Fully charged HUD"))
                } header: {
                    Text("Battery HUDs")
                } footer: {
                    Text("These temporary HUDs recreate the charging, low-battery, and full-battery notch alerts.")
                }
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Charging duration")
                            Spacer()
                            Text("\(chargingBatteryHUDDuration)s")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: chargingDurationBinding, in: 1...10, step: 1)
                    }
                    .settingsHighlight(id: highlightID("Charging duration"))
                    .disabled(!showPowerStatusNotifications || !showChargingBatteryHUD)
                    .opacity(sectionOpacity(showPowerStatusNotifications && showChargingBatteryHUD))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Low battery duration")
                            Spacer()
                            Text("\(lowBatteryHUDDuration)s")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: lowBatteryDurationBinding, in: 1...10, step: 1)
                    }
                    .settingsHighlight(id: highlightID("Low battery duration"))
                    .disabled(!showPowerStatusNotifications || !showLowBatteryHUD)
                    .opacity(sectionOpacity(showPowerStatusNotifications && showLowBatteryHUD))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Full battery duration")
                            Spacer()
                            Text("\(fullBatteryHUDDuration)s")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: fullBatteryDurationBinding, in: 1...10, step: 1)
                    }
                    .settingsHighlight(id: highlightID("Full battery duration"))
                    .disabled(!showPowerStatusNotifications || !showFullBatteryHUD)
                    .opacity(sectionOpacity(showPowerStatusNotifications && showFullBatteryHUD))
                } header: {
                    Text("HUD Duration")
                }
                Section {
                    Button {
                        batteryStatusViewModel.triggerTestHUD(kind: .charging)
                    } label: {
                        Label("Test charging HUD", systemImage: "bolt.fill")
                    }
                    .disabled(!showPowerStatusNotifications || !showChargingBatteryHUD)

                    Button {
                        batteryStatusViewModel.triggerTestHUD(kind: .lowBattery)
                    } label: {
                        Label("Test low battery HUD", systemImage: "battery.25")
                    }
                    .disabled(!showPowerStatusNotifications || !showLowBatteryHUD)

                    Button {
                        batteryStatusViewModel.triggerTestHUD(kind: .fullBattery)
                    } label: {
                        Label("Test full battery HUD", systemImage: "battery.100")
                    }
                    .disabled(!showPowerStatusNotifications || !showFullBatteryHUD)
                } header: {
                    Text("HUD Tests")
                } footer: {
                    Text("Runs the real notch animation on the current target display. If an external screen is using Dynamic Island mode, the battery HUD is sent there first.")
                }
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Low battery style", selection: $lowBatteryHUDStyle) {
                            ForEach(BatteryNotificationStyle.allCases) { style in
                                Text(style.title)
                                    .tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("Compact matches the charging HUD. Standard uses the expanded DynamicNotch-style card.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .settingsHighlight(id: highlightID("Low battery style"))


                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Low battery threshold")
                            Spacer()
                            Text("\(lowBatteryHUDThreshold)%")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: lowBatteryThresholdBinding, in: 5...30, step: 1)
                    }
                    .settingsHighlight(id: highlightID("Low battery threshold"))
                } header: {
                    Text("Low Battery")
                }
                .disabled(!showPowerStatusNotifications || !showLowBatteryHUD)
                .opacity(sectionOpacity(showPowerStatusNotifications && showLowBatteryHUD))

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Full battery style", selection: $fullBatteryHUDStyle) {
                            ForEach(BatteryNotificationStyle.allCases) { style in
                                Text(style.title)
                                    .tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("Compact keeps the alert inline. Standard uses the taller full-charge HUD with the charging animation.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .settingsHighlight(id: highlightID("Full battery style"))


                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Full charge threshold")
                            Spacer()
                            Text("\(fullBatteryHUDThreshold)%")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: fullBatteryThresholdBinding, in: 80...100, step: 1)
                    }
                    .settingsHighlight(id: highlightID("Full charge threshold"))
                } header: {
                    Text("Full Battery")
                }
                .disabled(!showPowerStatusNotifications || !showFullBatteryHUD)
                .opacity(sectionOpacity(showPowerStatusNotifications && showFullBatteryHUD))
            } else {
                ContentUnavailableView {
                    VStack(spacing: 16) {
                        Image(systemName: "battery.100percent.slash")
                            .font(.title)
                        Text("Battery settings and informations are only available on MacBooks")
                            .font(.title3)
                    }
                }
            }
        }
        .navigationTitle("Battery")
    }
}
