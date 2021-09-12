import Combine
import Foundation
import NotificationSettingsEditor
import SwiftUIKit
import UIKit

public struct SettingsEditorState: Hashable, Equatable {
  public enum Appearance: Int { case dark, light, auto }

  public var appearance: Appearance = .dark
  public var neverSleep: Bool = true

  public struct ScheduleSettings: Hashable, Equatable {
    public var periodDuration: Int = 15
    public var shortBreakDuration: Int = 5
    public var longBreakDuration: Int = 10

    public var longBreakFrequency: Int = 4
    public var dailyTarget: Int = 10

    public var pauseBeforeStartingWorkPeriods: Bool = false
    public var pauseBeforeStartingBreaks: Bool = false
    public var resetWorkPeriodOnStop: Bool = true
  }

  public var schedule: ScheduleSettings = .init()
  public var notifications: NotificationSettingsEditorState = .init()

  public init() {}
}

public enum SettingsEditorAction: Equatable {
  case workDurationTapped(Int)
  case shortBreakDurationTapped(Int)
  case longBreakDurationTapped(Int)

  case longBreaksFrequencyTapped(Int)
  case dailyTargetTapped(Int)

  case pauseBeforeWorkPeriodTapped(Bool)
  case pauseBeforeBreakTapped(Bool)
  case resetWorkPeriodOnStopTapped(Bool)

  case themeTapped(SettingsEditorState.Appearance)
  case neverSleepTapped(Bool)

  case notification(NotificationSettingsEditorAction)
}

public struct SettingsEditorEnvironment {
  public init() {}
}

public func settingsEditorReducer(state: inout SettingsEditorState,
                                  action: SettingsEditorAction,
                                  environment _: SettingsEditorEnvironment)
{
  switch action {
  case let .workDurationTapped(value):
    state.schedule.periodDuration = value
  case let .shortBreakDurationTapped(value):
    state.schedule.shortBreakDuration = value
  case let .longBreakDurationTapped(value):
    state.schedule.longBreakDuration = value
  case let .longBreaksFrequencyTapped(value):
    state.schedule.longBreakFrequency = value
  case let .dailyTargetTapped(value):
    state.schedule.dailyTarget = value
  case let .pauseBeforeWorkPeriodTapped(value):
    state.schedule.pauseBeforeStartingWorkPeriods = value
  case let .pauseBeforeBreakTapped(value):
    state.schedule.pauseBeforeStartingBreaks = value
  case let .resetWorkPeriodOnStopTapped(value):
    state.schedule.resetWorkPeriodOnStop = value
  case let .themeTapped(value):
    state.appearance = value
  case let .neverSleepTapped(value):
    state.neverSleep = value
  case let .notification(action):
    notificationSettingsEditorReducer(state: &state.notifications,
                                      action: action,
                                      environment: NotificationSettingsEditorEnvironment())
  }
}

public func SettingsEditor(settings: AnyPublisher<SettingsEditorState, Never>,
                           callback: @escaping (SettingsEditorAction) -> Void) -> UINavigationController
{
  UINavigationController(rootViewController: settingsEditor(settings.eraseToAnyPublisher(), callback: callback))
    .setPrefersLargeTitle(true)
}

private func settingsEditor(_ publisher: AnyPublisher<SettingsEditorState, Never>,
                            callback: @escaping (SettingsEditorAction) -> Void) -> UITableViewController
{
  Form(userData: publisher) { stateOverTime, currentState in
    Section(header: "Time Management") {
      Picker("Work Period",
             subtitle: "Duration",
             selection: stateOverTime.map(\.schedule.periodDuration).eraseToAnyPublisher(),
             values: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60],
             valueTitle: minuteText) { callback(.workDurationTapped($0)) }

      Picker("Short Break",
             subtitle: "Duration",
             selection: stateOverTime.map(\.schedule.shortBreakDuration).eraseToAnyPublisher(),
             values: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60],
             valueTitle: minuteText) { callback(.shortBreakDurationTapped($0)) }

      Picker("Long Break",
             subtitle: "Duration",
             selection: stateOverTime
               .map(\.schedule.longBreakDuration).eraseToAnyPublisher(),
             values: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60],
             valueTitle: minuteText) { callback(.longBreakDurationTapped($0)) }
    }

    Section(header: "Sessions & Targets") {
      Picker("Long Breaks",
             subtitle: "Session Frequency",
             selection: stateOverTime.map(\.schedule.longBreakFrequency).eraseToAnyPublisher(),

             values: [2, 3, 4, 5, 6, 7, 8])
      { "Every \($0) Work Periods" }
      callback: { callback(.longBreaksFrequencyTapped($0)) }

      Picker("Daily Target",
             selection: stateOverTime.map(\.schedule.dailyTarget).eraseToAnyPublisher(),
             values: [2, 3, 4, 5, 6, 7, 8, 9, 10])
      { "\($0) Work Periods" }
      callback: { callback(.dailyTargetTapped($0)) }
    }

    Section(header: "Alerts") {
      NotificationSettingsRow(settings: stateOverTime.map(\.notifications).eraseToAnyPublisher()) {
        callback(.notification($0))
      }

      if currentState.notifications.showNotifications {
        Toggle(title: "Play Sound", isOn: stateOverTime.map(\.notifications.playSound).eraseToAnyPublisher()) { value in
          callback(.notification(.playSoundToggled(value)))
        }
      }
    }

    Section(header: "Workflow") {
      Toggle(title: "Pause Before Starting Work Periods",
             isOn: stateOverTime.map(\.schedule.pauseBeforeStartingWorkPeriods).eraseToAnyPublisher()) {
        callback(.pauseBeforeWorkPeriodTapped($0))
      }

      Toggle(title: "Pause Before Starting Break",
             isOn: stateOverTime.map(\.schedule.pauseBeforeStartingBreaks).eraseToAnyPublisher()) {
        callback(.pauseBeforeBreakTapped($0))
      }

      Toggle(title: "Reset Work Period On Stop",
             isOn: stateOverTime.map(\.schedule.resetWorkPeriodOnStop).eraseToAnyPublisher()) {
        callback(.resetWorkPeriodOnStopTapped($0))
      }
    }

    Section(header: "Theme") {
      Picker("Theme",
             selection: stateOverTime.map(\.appearance).eraseToAnyPublisher(),
             values: [.dark, .light, .auto],
             valueTitle: themeTitle) {
        callback(.themeTapped($0))
      }
    }

    Section(header: "Power") {
      Toggle(title: "Never Sleep",
             isOn: stateOverTime
               .map(\.neverSleep)
               .eraseToAnyPublisher()) {
        callback(.neverSleepTapped($0))
      }
    }
  }
  .navigationBarTitle("Settings")
}

private extension SettingsEditorState.Appearance {
  var title: String {
    switch self {
    case .dark: return "Dark"
    case .light: return "Light"
    case .auto: return "Automatic"
    }
  }
}

private func themeTitle(value: SettingsEditorState.Appearance) -> String {
  value.title
}

private func minuteText(_ value: Int) -> String {
  value == 60
    ? " 1 Hour"
    : "\(String(value)) Minutes"
}

private class NotificationSettingsRow: UITableViewCell, CellPickable {
  private var cancellables: [AnyCancellable] = []
  private var settings: AnyPublisher<NotificationSettingsEditorState, Never>
  private var callback: (NotificationSettingsEditorAction) -> Void

  public init(settings: AnyPublisher<NotificationSettingsEditorState, Never>,
              callback: @escaping (NotificationSettingsEditorAction) -> Void)
  {
    self.settings = settings
    self.callback = callback

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
    NotificationSettingsEditor(userData: settings, userAction: callback)
      .navigationBarTitle("Notification Settings")
      .setLargeTitleDisplayMode(.never)
  }
}
