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



struct CalendarSettings: View {
    @ObservedObject private var calendarManager = CalendarManager.shared
    @Default(.showCalendar) var showCalendar: Bool
    @Default(.enableReminderLiveActivity) var enableReminderLiveActivity
    @Default(.reminderPresentationStyle) var reminderPresentationStyle
    @Default(.reminderLeadTime) var reminderLeadTime
    @Default(.reminderSneakPeekDuration) var reminderSneakPeekDuration
    @Default(.enableLockScreenReminderWidget) var enableLockScreenReminderWidget
    @Default(.lockScreenReminderChipStyle) var lockScreenReminderChipStyle
    @Default(.hideAllDayEvents) var hideAllDayEvents
    @Default(.hideCompletedReminders) var hideCompletedReminders
    @Default(.showFullEventTitles) var showFullEventTitles
    @Default(.autoScrollToNextEvent) var autoScrollToNextEvent
    @Default(.lockScreenShowCalendarCountdown) private var lockScreenShowCalendarCountdown
    @Default(.lockScreenShowCalendarEvent) private var lockScreenShowCalendarEvent
    @Default(.lockScreenShowCalendarEventEntireDuration) private var lockScreenShowCalendarEventEntireDuration
    @Default(.lockScreenShowCalendarEventAfterStartWindow) private var lockScreenShowCalendarEventAfterStartWindow
    @Default(.lockScreenShowCalendarTimeRemaining) private var lockScreenShowCalendarTimeRemaining
    @Default(.lockScreenShowCalendarStartTimeAfterBegins) private var lockScreenShowCalendarStartTimeAfterBegins
    @Default(.lockScreenCalendarEventLookaheadWindow) private var lockScreenCalendarEventLookaheadWindow
    @Default(.lockScreenCalendarSelectionMode) private var lockScreenCalendarSelectionMode
    @Default(.lockScreenSelectedCalendarIDs) private var lockScreenSelectedCalendarIDs
    @Default(.lockScreenShowCalendarEventAfterStartEnabled) private var lockScreenShowCalendarEventAfterStartEnabled
    @Default(.enableThirdPartyCalendarApp) private var enableThirdPartyCalendarApp
    @Default(.selectedCalendarApp) private var selectedCalendarApp
    @Default(.fantasticalDefaultView) private var fantasticalDefaultView

    private func highlightID(_ title: String) -> String {
        SettingsTab.calendar.highlightID(for: title)
    }

    private enum CalendarLookaheadOption: String, CaseIterable, Identifiable {
        case mins15 = "15m"
        case mins30 = "30m"
        case hour1 = "1h"
        case hours3 = "3h"
        case hours6 = "6h"
        case hours12 = "12h"
        case restOfDay = "rest_of_day"
        case allTime = "all_time"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .mins15: return "15 mins"
            case .mins30: return "30 mins"
            case .hour1: return "1 hour"
            case .hours3: return "3 hours"
            case .hours6: return "6 hours"
            case .hours12: return "12 hours"
            case .restOfDay: return "Rest of the day"
            case .allTime: return "All time"
            }
        }
    }

    var body: some View {
        Form {
            if !calendarManager.hasCalendarAccess || !calendarManager.hasReminderAccess {
                Text("Calendar or Reminder access is denied. Please enable it in System Settings.")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()

                HStack {
                    Button("Request Access") {
                        Task {
                            await calendarManager.checkCalendarAuthorization()
                            await calendarManager.checkReminderAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Open System Settings") {
                        if let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                            NSWorkspace.shared.open(settingsURL)
                        }
                    }
                }
            } else {
                // Permissions status
                Section(header: Text("Permissions")) {
                    HStack {
                        Text("Calendars")
                        Spacer()
                        Text(statusText(for: calendarManager.calendarAuthorizationStatus))
                            .foregroundColor(color(for: calendarManager.calendarAuthorizationStatus))
                    }
                    HStack {
                        Text("Reminders")
                        Spacer()
                        Text(statusText(for: calendarManager.reminderAuthorizationStatus))
                            .foregroundColor(color(for: calendarManager.reminderAuthorizationStatus))
                    }
                }

                Defaults.Toggle(key: .showCalendar) {
                    Text("Show calendar")
                }
                .settingsHighlight(id: highlightID("Show calendar"))

                Section(header: Text("Event List")) {
                    Toggle("Hide completed reminders", isOn: $hideCompletedReminders)
                        .settingsHighlight(id: highlightID("Hide completed reminders"))
                    Toggle("Show full event titles", isOn: $showFullEventTitles)
                        .settingsHighlight(id: highlightID("Show full event titles"))
                    Toggle("Auto-scroll to next event", isOn: $autoScrollToNextEvent)
                        .settingsHighlight(id: highlightID("Auto-scroll to next event"))
                }

                Section(header: Text("All-Day Events")) {
                    Toggle("Hide all-day events", isOn: $hideAllDayEvents)
                        .settingsHighlight(id: highlightID("Hide all-day events"))
                        .disabled(!showCalendar)

                    Text("Turn this off to include all-day entries in the notch calendar and reminder live activity.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(header: Text("Reminder Live Activity")) {
                    Defaults.Toggle(key: .enableReminderLiveActivity) {
                        Text("Enable reminder live activity")
                    }
                    .settingsHighlight(id: highlightID("Enable reminder live activity"))

                    Picker("Countdown style", selection: $reminderPresentationStyle) {
                        ForEach(ReminderPresentationStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!enableReminderLiveActivity)
                    .settingsHighlight(id: highlightID("Countdown style"))

                    HStack {
                        Text("Notify before")
                        Slider(
                            value: Binding(
                                get: { Double(reminderLeadTime) },
                                set: { reminderLeadTime = Int($0) }
                            ),
                            in: 1...60,
                            step: 1
                        )
                        .disabled(!enableReminderLiveActivity)
                        Text("\(reminderLeadTime) min")
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }

                    HStack {
                        Text("Sneak peek duration")
                        Slider(
                            value: $reminderSneakPeekDuration,
                            in: 3...20,
                            step: 1
                        )
                        .disabled(!enableReminderLiveActivity)
                        Text("\(Int(reminderSneakPeekDuration)) s")
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }

                Section(header: Text("Lock Screen Reminder Widget")) {
                    Defaults.Toggle(key: .enableLockScreenReminderWidget) {
                        Text("Show lock screen reminder")
                    }
                    .settingsHighlight(id: highlightID("Show lock screen reminder"))

                    Picker("Chip color", selection: $lockScreenReminderChipStyle) {
                        ForEach(LockScreenReminderChipStyle.allCases) { style in
                            Text(style.localizedName).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!enableLockScreenReminderWidget || !enableReminderLiveActivity)
                    .settingsHighlight(id: highlightID("Chip color"))
                }

                Section(
                    header: Text("Calendar Widget"),
                    footer: Text("Displays your next upcoming calendar event above or below the weather capsule. Calendar selection here is independent from the Dynamic Island calendar filter.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                ) {
                    Defaults.Toggle(key: .lockScreenShowCalendarEvent) {
                        Text("Show next calendar event")
                    }
                    .settingsHighlight(id: highlightID("Show next calendar event"))

                    LabeledContent("Show events within the next") {
                        HStack {
                            Spacer(minLength: 0)
                            Picker("", selection: $lockScreenCalendarEventLookaheadWindow) {
                                ForEach(CalendarLookaheadOption.allCases) { option in
                                    Text(option.title).tag(option.rawValue)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .disabled(!lockScreenShowCalendarEvent)
                    .settingsHighlight(id: highlightID("Show events within the next"))

                    Toggle("Show events from all calendars", isOn: Binding(
                        get: { lockScreenCalendarSelectionMode == "all" },
                        set: { useAll in
                            if useAll {
                                lockScreenCalendarSelectionMode = "all"
                            } else {
                                lockScreenCalendarSelectionMode = "selected"
                                lockScreenSelectedCalendarIDs = Set(calendarManager.eventCalendars.map { $0.id })
                            }
                        }
                    ))
                    .disabled(!lockScreenShowCalendarEvent)
                    .settingsHighlight(id: highlightID("Show events from all calendars"))

                    if lockScreenCalendarSelectionMode != "all" {
                        HStack {
                            Spacer()
                            Button("Deselect All") {
                                lockScreenSelectedCalendarIDs = []
                            }
                            .buttonStyle(.link)
                        }
                        .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(calendarManager.eventCalendars, id: \.id) { calendar in
                                Toggle(isOn: Binding(
                                    get: { lockScreenSelectedCalendarIDs.contains(calendar.id) },
                                    set: { isOn in
                                        if isOn {
                                            lockScreenSelectedCalendarIDs.insert(calendar.id)
                                        } else {
                                            lockScreenSelectedCalendarIDs.remove(calendar.id)
                                        }
                                    }
                                )) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color(calendar.color))
                                            .frame(width: 8, height: 8)
                                        Text(calendar.title)
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                        .padding(.leading, 2)
                        .disabled(!lockScreenShowCalendarEvent)
                    }

                    Defaults.Toggle(key: .lockScreenShowCalendarCountdown) {
                        Text("Show countdown")
                    }
                    .disabled(!lockScreenShowCalendarEvent)
                    .settingsHighlight(id: highlightID("Show countdown"))

                    Defaults.Toggle(key: .lockScreenShowCalendarEventEntireDuration) {
                        Text("Show event for entire duration")
                    }
                    .disabled(!lockScreenShowCalendarEvent)
                    .settingsHighlight(id: highlightID("Show event for entire duration"))
                    .onChange(of: Defaults[.lockScreenShowCalendarEventEntireDuration]) { _, newValue in
                        if newValue {
                            Defaults[.lockScreenShowCalendarEventAfterStartEnabled] = false
                        }
                    }

                    Defaults.Toggle(key: .lockScreenShowCalendarEventAfterStartEnabled) {
                        Text("Hide active event and show next upcoming event")
                    }
                    .disabled(!lockScreenShowCalendarEvent || lockScreenShowCalendarEventEntireDuration)
                    .settingsHighlight(id: highlightID("Hide active event and show next upcoming event"))

                    LabeledContent("Show event after it starts") {
                        HStack {
                            Spacer(minLength: 0)
                            Picker("", selection: $lockScreenShowCalendarEventAfterStartWindow) {
                                Text("1 min").tag("1m")
                                Text("5 mins").tag("5m")
                                Text("10 mins").tag("10m")
                                Text("15 mins").tag("15m")
                                Text("30 mins").tag("30m")
                                Text("45 mins").tag("45m")
                                Text("1 hour").tag("1h")
                                Text("2 hours").tag("2h")
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .disabled(!lockScreenShowCalendarEvent || lockScreenShowCalendarEventEntireDuration || !lockScreenShowCalendarEventAfterStartEnabled)

                    Text("Turn off 'Show event for entire duration' to use the post-start duration option.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Defaults.Toggle(key: .lockScreenShowCalendarTimeRemaining) {
                        Text("Show time remaining")
                    }
                    .disabled(!lockScreenShowCalendarEvent)
                    .settingsHighlight(id: highlightID("Show time remaining"))

                    Defaults.Toggle(key: .lockScreenShowCalendarStartTimeAfterBegins) {
                        Text("Show start time after event begins")
                    }
                    .disabled(!lockScreenShowCalendarEvent)
                    .settingsHighlight(id: highlightID("Show start time after event begins"))
                }
                
                // MARK: - Third-party Calendar Integration
                Section {
                    Defaults.Toggle(key: .enableThirdPartyCalendarApp) {
                        HStack {
                            Image(systemName: "ellipsis.calendar")
                                .foregroundStyle(.secondary)
                                .frame(width: 20, height: 20)
                            Text("Enable third-party calendar app launch")
                        }
                    }
                    .settingsHighlight(id: highlightID("Enable third-party calendar app launch"))
                    
                    if enableThirdPartyCalendarApp {
                        Picker("Calendar App", selection: $selectedCalendarApp) {
                            ForEach(ThirdPartyCalendarApp.allCases) { app in
                                HStack {
                                    AppIconImage(
                                        bundleIdentifiers: app.bundleIdentifiers,
                                        symbolFallback: app.fallbackIconName,
                                        symbolColor: app.fallbackIconColor
                                    )
                                    Text(app.displayName)
                                }
                                .tag(app)
                            }
                        }
                        .settingsHighlight(id: highlightID("Calendar App"))
                        
                        if selectedCalendarApp == .fantastical {
                            Picker("Default View", selection: $fantasticalDefaultView) {
                                ForEach(FantasticalViewStyle.allCases, id: \.self) { style in
                                    Text(style.displayName).tag(style)
                                }
                            }
                            .settingsHighlight(id: highlightID("Fantastical Default View"))
                        }
                    }
                } header: {
                    Text("Third-party Calendar Integration")
                } footer: {
                    Text("When enabled, clicking on calendar events will open the selected third-party calendar app instead of Apple Calendar.")
                }

                Section(header: Text("Select Calendars")) {
                    let grouped = Dictionary(grouping: calendarManager.allCalendars, by: \.accountName)
                    let sortedAccounts = grouped.keys.sorted()

                    ForEach(sortedAccounts, id: \.self) { account in
                        let accountCalendars = grouped[account] ?? []
                        let allAccountSelected = accountCalendars.allSatisfy { calendarManager.getCalendarSelected($0) }

                        Section(header: HStack {
                            Text(account)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { allAccountSelected },
                                set: { isSelected in
                                    Task {
                                        await calendarManager.setCalendarsSelected(accountCalendars, isSelected: isSelected)
                                    }
                                }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .disabled(!showCalendar)
                        }) {
                            ForEach(accountCalendars, id: \.id) { calendar in
                                Toggle(isOn: Binding(
                                    get: { calendarManager.getCalendarSelected(calendar) },
                                    set: { isSelected in
                                        Task {
                                            await calendarManager.setCalendarSelected(calendar, isSelected: isSelected)
                                        }
                                    }
                                )) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color(calendar.color))
                                            .frame(width: 8, height: 8)
                                        Text(calendar.title)
                                    }
                                }
                                .disabled(!showCalendar)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await calendarManager.checkCalendarAuthorization()
                await calendarManager.checkReminderAuthorization()
            }
        }
        .navigationTitle("Calendar")
    }

    private func statusText(for status: EKAuthorizationStatus) -> String {
        switch status {
        case .fullAccess, .authorized: return String(localized: "Full Access")
        case .writeOnly: return String(localized: "Write Only")
        case .denied: return String(localized: "Denied")
        case .restricted: return String(localized: "Restricted")
        case .notDetermined: return String(localized: "Not Determined")
        @unknown default: return String(localized: "Unknown")
        }
    }

    private func color(for status: EKAuthorizationStatus) -> Color {
        switch status {
        case .fullAccess, .authorized: return .green
        case .writeOnly: return .yellow
        case .denied, .restricted: return .red
        case .notDetermined: return .secondary
        @unknown default: return .secondary
        }
    }
}
