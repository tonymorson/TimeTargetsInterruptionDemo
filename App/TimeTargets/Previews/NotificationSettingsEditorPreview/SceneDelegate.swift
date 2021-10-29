import Combine
import NotificationSettingsEditor
import UIKit

let settings = CurrentValueSubject<NotificationsState, Never>(NotificationsState())
let environment = NotificationSettingsEditorEnvironment()

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var cancellables: Set<AnyCancellable> = []
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }

    let editor = NotificationSettingsEditor(userData: settings.eraseToAnyPublisher())

    editor.actions.sink { action in
      notificationSettingsEditorReducer(state: &settings.value, action: action, environment: environment)
    }
    .store(in: &cancellables)

    let window = UIWindow(windowScene: scene)

    window.rootViewController = UINavigationController(rootViewController: editor)
    window.makeKeyAndVisible()

    self.window = window
  }
}
