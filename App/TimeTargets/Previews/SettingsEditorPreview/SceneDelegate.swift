import Combine
import SettingsEditor
import UIKit

let settings = CurrentValueSubject<SettingsEditorState, Never>(.init())

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var cancellables: Set<AnyCancellable> = []
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }

    let editor = SettingsEditor(state: settings.eraseToAnyPublisher())

    let actions = editor.sentActions

    actions.sink { action in
      settingsEditorReducer(state: &settings.value, action: action)
    }
    .store(in: &cancellables)

    let window = UIWindow(windowScene: scene)
    window.rootViewController = editor
    window.makeKeyAndVisible()

    self.window = window
  }
}
