import Combine
import Durations
import Foundation
import Notifications
import SwiftUIKit
import UIKit

public enum Appearance: Int, Codable, Equatable { case dark, light, auto }

public struct SettingsEditorState: Equatable {
  public struct PeriodSettings: Equatable {
    public var workPeriodDuration: Duration
    public var shortBreakDuration: Duration
    public var longBreakDuration: Duration

    public var longBreakFrequency: Int
    public var dailyTarget: Int

    public var pauseBeforeStartingWorkPeriods: Bool
    public var pauseBeforeStartingBreaks: Bool
    public var resetWorkPeriodOnStop: Bool

    public init(periodDuration: Duration,
                shortBreakDuration: Duration,
                longBreakDuration: Duration,
                longBreakFrequency: Int,
                dailyTarget: Int,
                pauseBeforeStartingWorkPeriods: Bool,
                pauseBeforeStartingBreaks: Bool,
                resetWorkPeriodOnStop: Bool)
    {
      workPeriodDuration = periodDuration
      self.shortBreakDuration = shortBreakDuration
      self.longBreakDuration = longBreakDuration
      self.longBreakFrequency = longBreakFrequency
      self.dailyTarget = dailyTarget
      self.pauseBeforeStartingWorkPeriods = pauseBeforeStartingWorkPeriods
      self.pauseBeforeStartingBreaks = pauseBeforeStartingBreaks
      self.resetWorkPeriodOnStop = resetWorkPeriodOnStop
    }
  }

  public var appearance: Appearance
  public var neverSleep: Bool
  public var notifications: NotificationsSettingsState
  public var periods: PeriodSettings

  public var interruptionTimeout: Double

  public init(appearance: Appearance,
              neverSleep: Bool,
              notifications: NotificationsSettingsState,
              periods: SettingsEditorState.PeriodSettings,
              interruptionTimeout: Double = 3)
  {
    self.appearance = appearance
    self.neverSleep = neverSleep
    self.notifications = notifications
    self.periods = periods
    self.interruptionTimeout = interruptionTimeout
  }
}

public enum SettingsEditorAction: Equatable, Codable {
  case workDurationTapped(Duration)
  case shortBreakDurationTapped(Duration)
  case longBreakDurationTapped(Duration)

  case longBreaksFrequencyTapped(Int)
  case dailyTargetTapped(Int)

  case pauseBeforeWorkPeriodTapped(Bool)
  case pauseBeforeBreakTapped(Bool)
  case resetWorkPeriodOnStopTapped(Bool)

  case themeTapped(Appearance)
  case neverSleepTapped(Bool)

  case notification(NotificationSettingsEditorAction)

  case interruptionTimeoutTapped(Double?)
}

public func settingsEditorReducer(state: inout SettingsEditorState,
                                  action: SettingsEditorAction)
{
  switch action {
  case .workDurationTapped(let value):
    state.periods.workPeriodDuration = value
  case .shortBreakDurationTapped(let value):
    state.periods.shortBreakDuration = value
  case .longBreakDurationTapped(let value):
    state.periods.longBreakDuration = value
  case .longBreaksFrequencyTapped(let value):
    state.periods.longBreakFrequency = value
  case .dailyTargetTapped(let value):
    state.periods.dailyTarget = value
  case .pauseBeforeWorkPeriodTapped(let value):
    state.periods.pauseBeforeStartingWorkPeriods = value
  case .pauseBeforeBreakTapped(let value):
    state.periods.pauseBeforeStartingBreaks = value
  case .resetWorkPeriodOnStopTapped(let value):
    state.periods.resetWorkPeriodOnStop = value
  case .themeTapped(let value):
    state.appearance = value
  case .neverSleepTapped(let value):
    state.neverSleep = value
  case .notification(let action):
    notificationSettingsEditorReducer(state: &state.notifications, action: action)
  case .interruptionTimeoutTapped(let timeout):
    state.interruptionTimeout = timeout ?? -1
  }
}

public final class SettingsEditor: UINavigationController {
  public var sentActions: PassthroughSubject<SettingsEditorAction, Never>

  public var onDismiss: () -> Void {
    set {
      (viewControllers.first as! SettingsEditorForm).setOnDismiss(newValue)
    }
    get {
      (viewControllers.first as! SettingsEditorForm).onDismiss
    }
  }

  public init(state: AnyPublisher<SettingsEditorState, Never>) {
    sentActions = PassthroughSubject<SettingsEditorAction, Never>()
    super.init(rootViewController: SettingsEditorForm(state: state, actions: sentActions).navigationBarTitle("Settings"))

    setPrefersLargeTitle(true)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class SettingsEditorForm: Form<SettingsEditorState> {
  public init(state: AnyPublisher<SettingsEditorState, Never>, actions: PassthroughSubject<SettingsEditorAction, Never>) {
    super.init(userData: state) { stateOverTime, currentState in
      Section(header: "Time Management") {
        Picker("Work Period",
               subtitle: "Duration",
               selection: stateOverTime.map(\.periods.workPeriodDuration).eraseToAnyPublisher(),
               values: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60].map(\.minutes),
               valueTitle: durationText) { actions.send(.workDurationTapped($0)) }

        Picker("Short Break",
               subtitle: "Duration",
               selection: stateOverTime.map(\.periods.shortBreakDuration).eraseToAnyPublisher(),
               values: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60].map(\.minutes),
               valueTitle: durationText) { actions.send(.shortBreakDurationTapped($0)) }

        Picker("Long Break",
               subtitle: "Duration",
               selection: stateOverTime
                 .map(\.periods.longBreakDuration).eraseToAnyPublisher(),
               values: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60].map(\.minutes),
               valueTitle: durationText) { actions.send(.longBreakDurationTapped($0)) }
      }

      Section(header: "Sessions & Targets") {
        Picker("Long Breaks",
               subtitle: "Session Frequency",
               selection: stateOverTime.map(\.periods.longBreakFrequency).eraseToAnyPublisher(),

               values: [2, 3, 4, 5, 6, 7, 8])
        { "Every \($0) Work Periods" }
          callback: { actions.send(.longBreaksFrequencyTapped($0)) }

        Picker("Daily Target",
               selection: stateOverTime.map(\.periods.dailyTarget).eraseToAnyPublisher(),
               values: [2, 3, 4, 5, 6, 7, 8, 9, 10])
        { "\($0) Work Periods" }
          callback: { actions.send(.dailyTargetTapped($0)) }
      }

      Section(header: "Workflow") {
        Toggle(title: "Pause Before Starting Work Periods",
               isOn: stateOverTime.map(\.periods.pauseBeforeStartingWorkPeriods).eraseToAnyPublisher()) {
          actions.send(.pauseBeforeWorkPeriodTapped($0))
        }

        Toggle(title: "Pause Before Starting Break",
               isOn: stateOverTime.map(\.periods.pauseBeforeStartingBreaks).eraseToAnyPublisher()) {
          actions.send(.pauseBeforeBreakTapped($0))
        }

        Toggle(title: "Reset Work Period On Stop",
               isOn: stateOverTime.map(\.periods.resetWorkPeriodOnStop).eraseToAnyPublisher()) {
          actions.send(.resetWorkPeriodOnStopTapped($0))
        }
      }

      Section(header: "Activity Logs") {
        Picker("Ask About Pauses",
               subtitle: "Trigger an interruption after a pause",
               selection: stateOverTime.map(\.interruptionTimeout).eraseToAnyPublisher(),
               values: [0, 1, 2, 3, 4, 5, 10, 15, 30, -1],
               valueTitle: { duration in
                 if duration == 0 { return "Always" }
                 if duration == -1 { return "Never" }
                 return "Longer than \(Int(duration)) Secs"

               }) { actions.send(.interruptionTimeoutTapped($0)) }
      }

      Section(header: "Alerts") {
        NotificationSettingsRow(settings: stateOverTime.map(\.notifications).eraseToAnyPublisher(), actions: actions)

        if currentState.notifications.showNotifications {
          Toggle(title: "Play Sound", isOn: stateOverTime.map(\.notifications.playSound).eraseToAnyPublisher()) { value in
            actions.send(.notification(.playSoundToggled(value)))
          }
        }
      }

      Section(header: "Theme") {
        Picker("Theme",
               selection: stateOverTime.map(\.appearance).eraseToAnyPublisher(),
               values: [.dark, .light, .auto],
               valueTitle: themeTitle) {
          actions.send(.themeTapped($0))
        }
      }

      Section(header: "Power") {
        Toggle(title: "Never Sleep",
               isOn: stateOverTime
                 .map(\.neverSleep)
                 .eraseToAnyPublisher()) {
          actions.send(.neverSleepTapped($0))
        }
      }
    }
  }
}

private extension Appearance {
  var title: String {
    switch self {
    case .dark: return "Dark"
    case .light: return "Light"
    case .auto: return "Automatic"
    }
  }
}

private func themeTitle(value: Appearance) -> String {
  value.title
}

private func durationText(_ value: Duration) -> String {
  value.asMinutes == 60
    ? " 1 Hour"
    : "\(String(Int(value.asMinutes))) Minutes"
}

private class NotificationSettingsRow: UITableViewCell, CellPickable {
  public var actions: PassthroughSubject<SettingsEditorAction, Never>

  private var cancellables: [AnyCancellable] = []
  private var settings: AnyPublisher<NotificationsSettingsState, Never>

  public init(settings: AnyPublisher<NotificationsSettingsState, Never>,
              actions: PassthroughSubject<SettingsEditorAction, Never>)
  {
    self.settings = settings
    self.actions = actions

    super.init(style: .value1, reuseIdentifier: "Notifications")

    accessoryType = .disclosureIndicator
    textLabel?.text = "Notifications"

    settings.map(\.showNotifications)
      .map { $0 ? "On" : "Off" }
      .sink { [weak self] value in
        self?.detailValue = value
      }
      .store(in: &cancellables)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var detailValue: String {
    set { detailTextLabel?.text = newValue }
    get { detailTextLabel?.text ?? "" }
  }

  public func makeListPicker() -> UITableViewController {
    let editor = NotificationSettingsEditor(userData: settings)
      .navigationBarTitle("Notification Settings")
      .setLargeTitleDisplayMode(.never)

    editor.actions.map {
      SettingsEditorAction.notification($0)
    }.sink {
      self.actions.send($0)
    }
    .store(in: &cancellables)

    return editor
  }
}
