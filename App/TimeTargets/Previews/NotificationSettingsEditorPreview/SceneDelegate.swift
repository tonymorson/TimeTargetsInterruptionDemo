import Combine
import NotificationSettingsEditor
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  let settings = CurrentValueSubject<NotificationSettingsEditorState, Never>(NotificationSettingsEditorState())

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }

    let editor = NotificationSettingsEditor(userData: settings.eraseToAnyPublisher()) {
      switch $0 {
      case let .showNotificationsToggled(value):
        self.settings.value.showNotifications = value
      case let .playSoundToggled(value):
        self.settings.value.playSound = value
      case let .onStartPeriodToggled(value):
        self.settings.value.onStartPeriod = value
      case let .onStartBreakToggled(value):
        self.settings.value.onStartBreak = value
      case let .onLongPauseToggled(value):
        self.settings.value.onLongPause = value
      case let .onHalfwayToDailyToggled(value):
        self.settings.value.onHalfwayToDailyTarget = value
      case let .onReachingDailyTargetToggled(value):
        self.settings.value.onReachingDailyTarget = value
      }
    }

    let window = UIWindow(windowScene: scene)

    window.rootViewController = UINavigationController(rootViewController: editor)
    window.makeKeyAndVisible()

    self.window = window
  }
}
