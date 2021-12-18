import UIKit

// MARK: - AppDelegate

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_: UIApplication,
                   didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
  {
    true
  }
}

// MARK: - SceneDelegate

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene,
             willConnectTo _: UISceneSession,
             options _: UIScene.ConnectionOptions)
  {
    guard let scene = (scene as? UIWindowScene) else { return }

    let window = UIWindow(windowScene: scene)
    window.rootViewController = PreviewController()

    window.makeKeyAndVisible()
    self.window = window
  }
}
