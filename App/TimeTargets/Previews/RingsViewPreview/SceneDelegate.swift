import Combine
import RingsView
import UIKit

public struct RingsLayoutPerOrientationPair: Equatable {
  var portrait: RingsViewLayout
  var landscape: RingsViewLayout

  public init(portrait: RingsViewLayout, landscape: RingsViewLayout) {
    self.portrait = portrait
    self.landscape = landscape
  }
}

struct PreviewState: Equatable {
  var content: RingsData
  var layoutIsBestForPortraitMode: Bool
  var layout: RingsLayoutPerOrientationPair
  var prominentRing: RingIdentifier

  init() {
    layoutIsBestForPortraitMode = true

    content = .init()

    layout = RingsLayoutPerOrientationPair(portrait: .init(acentricAxis: .alongLongestDimension,
                                                           concentricity: 0.0,
                                                           scaleFactorWhenFullyAcentric: 1.0,
                                                           scaleFactorWhenFullyConcentric: 1.0),

                                           landscape: .init(acentricAxis: .alongLongestDimension,
                                                            concentricity: 1.0,
                                                            scaleFactorWhenFullyAcentric: 1.0,
                                                            scaleFactorWhenFullyConcentric: 1.0))

    prominentRing = .period
  }

  var rings: RingsViewState {
    get {
      layoutIsBestForPortraitMode
        ? RingsViewState(content: content, layout: layout.portrait, prominentRing: prominentRing)
        : RingsViewState(content: content, layout: layout.landscape, prominentRing: prominentRing)
    }
    set {
      content = newValue.content
      layoutIsBestForPortraitMode
        ? (layout.portrait = newValue.layout)
        : (layout.landscape = newValue.layout)
      prominentRing = newValue.prominentRing
    }
  }
}

enum PreviewAction {
  case rings(RingsViewAction)
  case mainViewBoundsChangedToPreferPortraitLayout(Bool)
}

func previewReducer(state: inout PreviewState, action: PreviewAction) {
  switch action {
  case let .rings(action):
    ringsViewReducer(state: &state.rings, action: action)

  case .mainViewBoundsChangedToPreferPortraitLayout(true):
    state.layoutIsBestForPortraitMode = true

  case .mainViewBoundsChangedToPreferPortraitLayout(false):
    state.layoutIsBestForPortraitMode = false
  }
}

private class PreviewStore {
  var cancellables: Set<AnyCancellable> = []
  @Published var input: PreviewAction?
  @Published var output = PreviewState()

  init() {
    $input
      .compactMap { $0 }
      .sink { previewReducer(state: &self.output, action: $0) }
      .store(in: &cancellables)
  }
}

private let store = PreviewStore()

final class RingsViewController: UIViewController {
  private var cancellables: Set<AnyCancellable> = []

  override func loadView() {
    view = RingsView(input: store
      .$output
      .map(\.rings)
      .eraseToAnyPublisher())

    (view as! RingsView)
      .$sentActions
      .compactMap { $0 }
      .map(PreviewAction.rings)
      .assign(to: \.input, on: store)
      .store(in: &cancellables)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    store.input = .mainViewBoundsChangedToPreferPortraitLayout(view.isPortrait)
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
