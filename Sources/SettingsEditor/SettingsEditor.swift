import Combine
import Foundation
import NotificationSettingsEditor
import SwiftUIKit
import UIKit

public struct SettingsEditorState: Equatable {
  public struct PeriodSettings: Equatable {
    public var periodDuration: Int = 15
    public var shortBreakDuration: Int = 5
    public var longBreakDuration: Int = 10

    public var longBreakFrequency: Int = 4
    public var dailyTarget: Int = 10

    public var pauseBeforeStartingWorkPeriods: Bool = false
    public var pauseBeforeStartingBreaks: Bool = false
    public var resetWorkPeriodOnStop: Bool = true
  }

  public enum Appearance: Int { case dark, light, auto }

  public var appearance: Appearance = .dark
  public var neverSleep: Bool = true
  public var notifications: NotificationSettingsEditorState = .init()
  public var periods: PeriodSettings = .init()

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
    state.periods.periodDuration = value
  case let .shortBreakDurationTapped(value):
    state.periods.shortBreakDuration = value
  case let .longBreakDurationTapped(value):
    state.periods.longBreakDuration = value
  case let .longBreaksFrequencyTapped(value):
    state.periods.longBreakFrequency = value
  case let .dailyTargetTapped(value):
    state.periods.dailyTarget = value
  case let .pauseBeforeWorkPeriodTapped(value):
    state.periods.pauseBeforeStartingWorkPeriods = value
  case let .pauseBeforeBreakTapped(value):
    state.periods.pauseBeforeStartingBreaks = value
  case let .resetWorkPeriodOnStopTapped(value):
    state.periods.resetWorkPeriodOnStop = value
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
               selection: stateOverTime.map(\.periods.periodDuration).eraseToAnyPublisher(),
               values: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60],
               valueTitle: minuteText) { actions.send(.workDurationTapped($0)) }

        Picker("Short Break",
               subtitle: "Duration",
               selection: stateOverTime.map(\.periods.shortBreakDuration).eraseToAnyPublisher(),
               values: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60],
               valueTitle: minuteText) { actions.send(.shortBreakDurationTapped($0)) }

        Picker("Long Break",
               subtitle: "Duration",
               selection: stateOverTime
                 .map(\.periods.longBreakDuration).eraseToAnyPublisher(),
               values: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60],
               valueTitle: minuteText) { actions.send(.longBreakDurationTapped($0)) }
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

      Section(header: "Alerts") {
        NotificationSettingsRow(settings: stateOverTime.map(\.notifications).eraseToAnyPublisher(), actions: actions)

        if currentState.notifications.showNotifications {
          Toggle(title: "Play Sound", isOn: stateOverTime.map(\.notifications.playSound).eraseToAnyPublisher()) { value in
            actions.send(.notification(.playSoundToggled(value)))
          }
        }
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
  public var actions: PassthroughSubject<SettingsEditorAction, Never>

  private var cancellables: [AnyCancellable] = []
  private var settings: AnyPublisher<NotificationSettingsEditorState, Never>

  public init(settings: AnyPublisher<NotificationSettingsEditorState, Never>,
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
