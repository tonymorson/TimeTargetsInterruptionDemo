import RingsView
import UIKit

final class RingsViewController: UIViewController {
  override func loadView() {
    view = RingsView()
  }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }

    let window = UIWindow(windowScene: scene)
    window.rootViewController = RingsViewController()

    window.makeKeyAndVisible()
    self.window = window
  }
}
