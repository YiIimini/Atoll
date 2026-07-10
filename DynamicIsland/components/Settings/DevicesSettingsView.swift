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



struct ExternalDisplayIntegrationsSection: View {
    @Default(.enableThirdPartyDDCIntegration) var enableThirdPartyDDCIntegration
    @Default(.thirdPartyDDCProvider) var thirdPartyDDCProvider
    @Default(.enableExternalVolumeControlListener) var enableExternalVolumeControlListener
    @Default(.volumeStepPercent) var volumeStepPercent
    @Default(.volumeFineStepPercent) var volumeFineStepPercent
    @Default(.brightnessStepPercent) var brightnessStepPercent
    @Default(.brightnessFineStepPercent) var brightnessFineStepPercent
    @ObservedObject private var betterDisplayManager = BetterDisplayManager.shared
    @ObservedObject private var lunarManager = LunarManager.shared

    private func highlightID(_ title: String) -> String {
        SettingsTab.hudAndOSD.highlightID(for: title)
    }

    private var providerStatusText: String {
        switch thirdPartyDDCProvider {
        case .betterDisplay:
            if betterDisplayManager.isRunning { return "Running" }
            if betterDisplayManager.isDetected { return "Not running" }
            return "Not detected"
        case .lunar:
            if lunarManager.isConnected { return "Connected" }
            if lunarManager.isRunning { return "Running" }
            if lunarManager.isDetected { return "Not running" }
            return "Not detected"
        }
    }

    private var providerStatusColor: Color {
        switch thirdPartyDDCProvider {
        case .betterDisplay:
            if betterDisplayManager.isRunning { return .green }
            if betterDisplayManager.isDetected { return .orange }
            return .secondary
        case .lunar:
            if lunarManager.isConnected { return .green }
            if lunarManager.isRunning { return .orange }
            if lunarManager.isDetected { return .orange }
            return .secondary
        }
    }

    private var providerStatusDescription: String {
        switch thirdPartyDDCProvider {
        case .betterDisplay:
            if !betterDisplayManager.isDetected {
                return "Install [BetterDisplay](https://betterdisplay.pro) to control external display brightness (and optional volume) through Atoll's HUD."
            }
            if !betterDisplayManager.isRunning {
                return "BetterDisplay is installed but not currently running. Launch BetterDisplay to enable integration."
            }
            return "BetterDisplay OSD events will be routed through Atoll's active HUD style. Brightness is always routed; volume is routed when external volume control listener is enabled below. Make sure BetterDisplay's OSD integration is enabled in Settings › Application › Integration."
        case .lunar:
            if !lunarManager.isDetected {
                return "Install [Lunar](https://lunar.fyi) to control external display brightness, contrast, and optional volume through Atoll's HUD via DDC."
            }
            if !lunarManager.isRunning {
                return "Lunar is installed but not currently running. Launch Lunar to enable integration."
            }
            if lunarManager.isConnected {
                return "Connected to Lunar's DDC socket. Brightness and contrast adjustments are shown through Atoll's HUD; volume follows when external volume control listener is enabled below."
            }
            return "Lunar is running but the socket connection is not yet established. It will connect automatically."
        }
    }

    private func refreshDetectionStatus() {
        switch thirdPartyDDCProvider {
        case .betterDisplay:
            betterDisplayManager.refreshDetectionStatus()
        case .lunar:
            lunarManager.refreshDetectionStatus()
        }
    }

    var body: some View {
        Form {
            Section {
                Stepper(value: $volumeStepPercent, in: 1...25) {
                    HStack {
                        Text("Volume step")
                        Spacer()
                        Text("\(volumeStepPercent)%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .settingsHighlight(id: highlightID("Volume step"))
                .disabled(enableExternalVolumeControlListener)

                Stepper(value: $volumeFineStepPercent, in: 1...25) {
                    HStack {
                        Text("Volume fine step")
                        Spacer()
                        Text("\(volumeFineStepPercent)%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .settingsHighlight(id: highlightID("Volume fine step"))
                .disabled(enableExternalVolumeControlListener)

                if enableExternalVolumeControlListener {
                    Text("Disabled while external display volume integration is active.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Stepper(value: $brightnessStepPercent, in: 1...25) {
                    HStack {
                        Text("Brightness step")
                        Spacer()
                        Text("\(brightnessStepPercent)%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .settingsHighlight(id: highlightID("Brightness step"))
                .disabled(enableThirdPartyDDCIntegration)

                Stepper(value: $brightnessFineStepPercent, in: 1...25) {
                    HStack {
                        Text("Brightness fine step")
                        Spacer()
                        Text("\(brightnessFineStepPercent)%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .settingsHighlight(id: highlightID("Brightness fine step"))
                .disabled(enableThirdPartyDDCIntegration)

                if enableThirdPartyDDCIntegration {
                    Text("Disabled while external display brightness integration is active.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Step size")
            } footer: {
                Text("Percent change per key press. Fine step applies when holding Shift+Option.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Section {
                Toggle("Enable third-party DDC app integration", isOn: $enableThirdPartyDDCIntegration)
                    .settingsHighlight(id: highlightID("Third-party DDC app integration"))

                if enableThirdPartyDDCIntegration {
                    Picker("Provider", selection: $thirdPartyDDCProvider) {
                        ForEach(ThirdPartyDDCProvider.allCases) { provider in
                            HStack {
                                AppIconImage(
                                    bundleIdentifiers: provider.bundleIdentifiers,
                                    symbolFallback: "display",
                                    symbolColor: .secondary
                                )
                                Text(provider.displayName)
                            }
                            .tag(provider)
                        }
                    }
                    .settingsHighlight(id: highlightID("Third-party DDC provider"))

                    Toggle("Enable external volume control listener", isOn: $enableExternalVolumeControlListener)
                        .settingsHighlight(id: highlightID("Enable external volume control listener"))

                    Text(
                        enableExternalVolumeControlListener
                        ? "Atoll's built-in volume key interception is disabled while external volume listening is on. Volume HUD/OSD will follow \(thirdPartyDDCProvider.displayName) payloads."
                        : "Atoll keeps native volume key interception. External provider volume payloads are ignored while this is off."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    HStack {
                        Text("Status")
                        Spacer()
                        Text(providerStatusText)
                            .font(.caption)
                            .foregroundStyle(providerStatusColor)
                    }

                    Text(providerStatusDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        refreshDetectionStatus()
                    } label: {
                        Label("Refresh detection", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.link)
                } else {
                    Text("Enable to route BetterDisplay or Lunar display adjustments through Atoll's active HUD style.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                if enableThirdPartyDDCIntegration {
                    Text("Atoll always listens to selected-provider brightness events, and listens to provider volume events only when external volume listener is enabled.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
    }
}

struct DevicesSettingsView: View {
    @Default(.progressBarStyle) var progressBarStyle
    @Default(.useBluetoothHUD3DIcon) private var useBluetoothHUD3DIcon

    private func highlightID(_ title: String) -> String {
        SettingsTab.devices.highlightID(for: title)
    }

    private var colorCodingDisabled: Bool {
        progressBarStyle == .segmented
    }

    var body: some View {
        Form {
            Section {
                Defaults.Toggle(key: .showBluetoothDeviceConnections) {
                    Text("Show Bluetooth device connections")
                }
                .settingsHighlight(id: highlightID("Show Bluetooth device connections"))
                Defaults.Toggle(key: .useCircularBluetoothBatteryIndicator) {
                    Text("Use circular battery indicator")
                }
                .settingsHighlight(id: highlightID("Use circular battery indicator"))
                Defaults.Toggle(key: .showBluetoothBatteryPercentageText) {
                    Text("Show battery percentage text in HUD")
                }
                .settingsHighlight(id: highlightID("Show battery percentage text in HUD"))
                Defaults.Toggle(key: .showBluetoothDeviceNameMarquee) {
                    Text("Scroll device name in HUD")
                }
                .settingsHighlight(id: highlightID("Scroll device name in HUD"))
                Defaults.Toggle(key: .showAirPodsListeningModeChanges) {
                    Text("Show AirPods listening mode changes")
                }
                .settingsHighlight(id: highlightID("Show AirPods listening mode changes"))
                VStack(alignment: .leading, spacing: 12) {
                    Text("HUD icon style")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 16) {
                        Spacer(minLength: 0)
                        BluetoothHUDIconStyleCard(
                            style: .symbol,
                            isSelected: !useBluetoothHUD3DIcon
                        ) {
                            useBluetoothHUD3DIcon = false
                        }
                        BluetoothHUDIconStyleCard(
                            style: .threeD,
                            isSelected: useBluetoothHUD3DIcon
                        ) {
                            useBluetoothHUD3DIcon = true
                        }
                        Spacer(minLength: 0)
                    }
                }
                .settingsHighlight(id: highlightID("Use 3D Bluetooth HUD icon"))
            } header: {
                Text("Bluetooth Audio Devices")
            } footer: {
                Text("Displays a HUD notification when Bluetooth audio devices (headphones, AirPods, speakers) connect, showing device name and battery level.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Section {
                Defaults.Toggle(key: .useColorCodedBatteryDisplay) {
                    Text("Color-coded battery display")
                }
                .disabled(colorCodingDisabled)
                .settingsHighlight(id: highlightID("Color-coded battery display"))
            } header: {
                Text("Battery Indicator Styling")
            } footer: {
                if progressBarStyle == .segmented {
                    Text("Color-coded fills are unavailable in Segmented mode. Switch to Hierarchical or Gradient inside Controls › Dynamic Island to adjust advanced options.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if Defaults[.useSmoothColorGradient] {
                    Text("Smooth transitions blend Green (0–60%), Yellow (60–85%), and Red (85–100%) through the entire fill. Adjust gradient behavior from Controls › Dynamic Island.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    Text("Discrete transitions snap between Green (0–60%), Yellow (60–85%), and Red (85–100%).")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Devices")
    }
}
