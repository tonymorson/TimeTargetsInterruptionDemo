import Combine
import SettingsEditor
import UIKit

let settings = CurrentValueSubject<SettingsEditorState, Never>(.init())

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }

    let editor = SettingsEditor(settings: settings.eraseToAnyPublisher()) {
      switch $0 {
      case let .workDurationTapped(value):
        settings.value.schedule.periodDuration = value
      case let .shortBreakDurationTapped(value):
        settings.value.schedule.shortBreakDuration = value
      case let .longBreakDurationTapped(value):
        settings.value.schedule.longBreakDuration = value
      case let .longBreaksFrequencyTapped(value):
        settings.value.schedule.longBreakFrequency = value
      case let .dailyTargetTapped(value):
        settings.value.schedule.dailyTarget = value
      case let .pauseBeforeWorkPeriodTapped(value):
        settings.value.schedule.pauseBeforeStartingWorkPeriods = value
      case let .pauseBeforeBreakTapped(value):
        settings.value.schedule.pauseBeforeStartingBreaks = value
      case let .resetWorkPeriodOnStopTapped(value):
        settings.value.schedule.resetWorkPeriodOnStop = value
      case let .themeTapped(value):
        settings.value.appearance = value
      case let .neverSleepTapped(value):
        settings.value.neverSleep = value
      case let .notification(action):
        switch action {
        case let .showNotificationsToggled(value):
          settings.value.notifications.showNotifications = value
        case let .playSoundToggled(value):
          settings.value.notifications.playSound = value
        case let .onStartPeriodToggled(value):
          settings.value.notifications.onStartPeriod = value
        case let .onStartBreakToggled(value):
          settings.value.notifications.onStartBreak = value
        case let .onLongPauseToggled(value):
          settings.value.notifications.onLongPause = value
        case let .onHalfwayToDailyToggled(value):
          settings.value.notifications.onHalfwayToDailyTarget = value
        case let .onReachingDailyTargetToggled(value):
          settings.value.notifications.onReachingDailyTarget = value
        }
      }
    }

    let window = UIWindow(windowScene: scene)
    window.rootViewController = editor
    window.makeKeyAndVisible()

    self.window = window
  }
}
