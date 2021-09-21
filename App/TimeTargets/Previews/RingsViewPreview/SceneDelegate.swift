import Combine
import RingsView
import UIKit

final class RingsViewController: UIViewController {
  private var cancellables: Set<AnyCancellable> = []
  private var ringsViewState = CurrentValueSubject<RingsViewState, Never>(RingsViewState())

  override func loadView() {
    view = RingsView(input: ringsViewState.eraseToAnyPublisher())

    (view as! RingsView)
      .$sentActions
      .compactMap { $0 }
      .sink { action in
        ringsViewReducer(state: &self.ringsViewState.value, action: action)
      }
      .store(in: &cancellables)
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
