import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }

    let window = UIWindow(windowScene: scene)
    window.rootViewController = ViewController()

    window.makeKeyAndVisible()
    self.window = window
  }
}
