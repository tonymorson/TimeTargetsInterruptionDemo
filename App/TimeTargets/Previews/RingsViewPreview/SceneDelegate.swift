import RingsView
import UIKit

final class RingsViewController: UIViewController {
  var savedPortraitArrangement: RingsLayout!
  var savedLandscapeArrangement: RingsLayout!

  var state = RingsViewState() {
    didSet {
      if view.isPortrait {
        savedPortraitArrangement = state.arrangement
      } else {
        savedLandscapeArrangement = state.arrangement
      }

      (view as! RingsView).state = state
    }
  }

  var environment = RingsViewEnvironment()

  override func loadView() {
    view = RingsView { _, ringsAction in
      ringsViewReducer(state: &self.state, action: ringsAction, environment: self.environment)
    }

    savedPortraitArrangement = (view as! RingsView).state.arrangement
    savedLandscapeArrangement = (view as! RingsView).state.arrangement

    savedLandscapeArrangement.concentricity = -1.0
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    coordinator.animate(alongsideTransition: { _ in
      if size.isPortrait {
        (self.view as! RingsView).state.arrangement = self.savedPortraitArrangement
      } else {
        (self.view as! RingsView).state.arrangement = self.savedLandscapeArrangement
      }
    })
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
