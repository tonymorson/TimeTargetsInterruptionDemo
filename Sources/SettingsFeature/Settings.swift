// import Combine
// import Durations
// import Foundation
// import Notifications
// import ComposableArchitecture
//
// public enum Appearance: Int, Codable, Equatable { case dark, light, auto }
//
// public struct SettingsEditorState: Equatable {
//
//  public enum Route {
//    case workDurationPicker
//    case shortBreakDurationPicker
//    case longBreakDurationPicker
//  }
//
//  public struct PeriodSettings: Equatable {
//    public var workPeriodDuration: Duration
//    public var shortBreakDuration: Duration
//    public var longBreakDuration: Duration
//
//    public var longBreakFrequency: Int
//    public var dailyTarget: Int
//
//    public var pauseBeforeStartingWorkPeriods: Bool
//    public var pauseBeforeStartingBreaks: Bool
//    public var resetWorkPeriodOnStop: Bool
//
//    public init(periodDuration: Duration,
//                shortBreakDuration: Duration,
//                longBreakDuration: Duration,
//                longBreakFrequency: Int,
//                dailyTarget: Int,
//                pauseBeforeStartingWorkPeriods: Bool,
//                pauseBeforeStartingBreaks: Bool,
//                resetWorkPeriodOnStop: Bool)
//    {
//      workPeriodDuration = periodDuration
//      self.shortBreakDuration = shortBreakDuration
//      self.longBreakDuration = longBreakDuration
//      self.longBreakFrequency = longBreakFrequency
//      self.dailyTarget = dailyTarget
//      self.pauseBeforeStartingWorkPeriods = pauseBeforeStartingWorkPeriods
//      self.pauseBeforeStartingBreaks = pauseBeforeStartingBreaks
//      self.resetWorkPeriodOnStop = resetWorkPeriodOnStop
//    }
//  }
//
//  public var appearance: Appearance
//  public var neverSleep: Bool
//  public var notifications: NotificationsSettingsState
//  public var periods: PeriodSettings
//
//  public var interruptionTimeout: Double
//
//  public var route: Route?
//
//  public init(appearance: Appearance,
//              neverSleep: Bool,
//              notifications: NotificationsSettingsState,
//              periods: SettingsEditorState.PeriodSettings,
//              route: Route?,
//              interruptionTimeout: Double = 3)
//  {
//    self.appearance = appearance
//    self.neverSleep = neverSleep
//    self.notifications = notifications
//    self.periods = periods
//    self.route = route
//    self.interruptionTimeout = interruptionTimeout
//  }
// }
//
// public enum SettingsEditorAction: Equatable, Codable {
//  case workDurationTapped(Duration)
//  case workDurationTapped2(Duration)
//  case shortBreakDurationTapped(Duration)
//  case longBreakDurationTapped(Duration)
//
//  case longBreaksFrequencyTapped(Int)
//  case dailyTargetTapped(Int)
//
//  case pauseBeforeWorkPeriodTapped(Bool)
//  case pauseBeforeBreakTapped(Bool)
//  case resetWorkPeriodOnStopTapped(Bool)
//
//  case themeTapped(Appearance)
//  case neverSleepTapped(Bool)
//
//  case notification(NotificationSettingsEditorAction)
//
//  case interruptionTimeoutTapped(Double?)
//
//  case pickerDismissed
// }
//
// let reducer = Reducer<SettingsEditorState, SettingsEditorAction, Void> { state, action, _ in
//
//  switch action {
//  case .workDurationTapped(let value):
//    state.route = .workDurationPicker
//  case .workDurationTapped2(let value):
//    state.periods.workPeriodDuration = value
//    state.route = nil
//  case .shortBreakDurationTapped(let value):
//    state.periods.shortBreakDuration = value
//    state.route = .shortBreakDurationPicker
//  case .longBreakDurationTapped(let value):
//    state.periods.longBreakDuration = value
//    state.route = .longBreakDurationPicker
//  case .longBreaksFrequencyTapped(let value):
//    state.periods.longBreakFrequency = value
//  case .dailyTargetTapped(let value):
//    state.periods.dailyTarget = value
//  case .pauseBeforeWorkPeriodTapped(let value):
//    state.periods.pauseBeforeStartingWorkPeriods = value
//  case .pauseBeforeBreakTapped(let value):
//    state.periods.pauseBeforeStartingBreaks = value
//  case .resetWorkPeriodOnStopTapped(let value):
//    state.periods.resetWorkPeriodOnStop = value
//  case .themeTapped(let value):
//    state.appearance = value
//  case .neverSleepTapped(let value):
//    state.neverSleep = value
//  case .notification(let action):
//    notificationSettingsEditorReducer(state: &state.notifications, action: action)
//  case .interruptionTimeoutTapped(let timeout):
//    state.interruptionTimeout = timeout ?? -1
//  case .pickerDismissed:
//    state.route = nil
//  }
//
//  return .none
// }
