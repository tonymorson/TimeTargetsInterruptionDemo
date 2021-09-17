import Combine
import RingsView
import UIKit

final class RingsViewController: UIViewController {
  private var cancellables: Set<AnyCancellable> = []
  private var savedPortraitArrangement: RingsViewLayout!
  private var savedLandscapeArrangement: RingsViewLayout!

  private var environment = RingsViewEnvironment()
  private var ringsViewState = CurrentValueSubject<RingsViewState, Never>(RingsViewState())

  override func loadView() {
    view = RingsView(input: ringsViewState.eraseToAnyPublisher())

    (view as! RingsView).sentActions.sink { action in
      ringsViewReducer(state: &self.ringsViewState.value, action: action, environment: self.environment)
    }
    .store(in: &cancellables)

    ringsViewState.sink { [weak self] value in
      guard let self = self else { return }
      if self.view.isPortrait {
        self.savedPortraitArrangement = value.arrangement
      } else {
        self.savedLandscapeArrangement = value.arrangement
      }
    }
    .store(in: &cancellables)

    savedPortraitArrangement = ringsViewState.value.arrangement
    savedLandscapeArrangement = ringsViewState.value.arrangement
    savedLandscapeArrangement.concentricity = -1.0
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    coordinator.animate(alongsideTransition: { _ in
      self.ringsViewState.value.arrangement = size.isPortrait
        ? self.savedPortraitArrangement
        : self.savedLandscapeArrangement
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
