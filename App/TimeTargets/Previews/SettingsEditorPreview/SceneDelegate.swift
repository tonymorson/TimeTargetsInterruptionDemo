import SettingsFeature
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }

    let editor = SettingsFeature.SettingsEditor()

    let window = UIWindow(windowScene: scene)
    window.rootViewController = UIHostingController(rootView: editor)
    window.makeKeyAndVisible()

    self.window = window
  }
}
