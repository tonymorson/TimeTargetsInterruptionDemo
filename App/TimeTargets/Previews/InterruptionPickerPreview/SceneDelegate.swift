import InterruptionPicker
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }

    let window = UIWindow(windowScene: scene)
    let interruptionPicker = InterruptionPickerViewController(state: .init(title: "", subtitle: ""))
    let navigationController = UINavigationController(rootViewController: UIViewController())

    window.rootViewController = navigationController
    window.makeKeyAndVisible()

    self.window = window

    interruptionPicker.modalPresentationStyle = .pageSheet
    if let sheet = interruptionPicker.sheetPresentationController {
      sheet.preferredCornerRadius = 20
      sheet.prefersGrabberVisible = true
      sheet.prefersScrollingExpandsWhenScrolledToEdge = false
      sheet.detents = [.medium(), .large()]
    }

    navigationController.present(interruptionPicker, animated: true)

    Task {
      for await action in interruptionPicker.actions {
        print (action)
      }
    }
  }
}
