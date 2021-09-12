import Combine
import SettingsEditor
import UIKit

let settings = CurrentValueSubject<SettingsEditorState, Never>(.init())
let environment = SettingsEditorEnvironment()

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }

    let editor = SettingsEditor(settings: settings.eraseToAnyPublisher()) { action in
      settingsEditorReducer(state: &settings.value, action: action, environment: environment)
    }

    let window = UIWindow(windowScene: scene)
    window.rootViewController = editor
    window.makeKeyAndVisible()

    self.window = window
  }
}
