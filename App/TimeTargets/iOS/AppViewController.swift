import Combine
import RingsView
import SwiftUIKit
import UIKit

struct AppViewState: Equatable {
  var isPortrait: Bool
  var ringsLayoutPortrait: RingsLayout
  var ringsLayoutLandscape: RingsLayout
  var ringsContent: RingsData

  init() {
    isPortrait = true
    ringsLayoutPortrait = RingsLayout(acentricAxis: .alongLongestDimension, concentricity: 0.0, focus: .period, scaleFactorWhenFullyAcentric: 1.0, scaleFactorWhenFullyConcentric: 1.0)
    ringsLayoutLandscape = RingsLayout(acentricAxis: .alongLongestDimension, concentricity: -1.0, focus: .period, scaleFactorWhenFullyAcentric: 1.0, scaleFactorWhenFullyConcentric: 1.0)
    ringsContent = RingsData()
  }

  var rings: RingsViewState {
    get {
      isPortrait
        ? .init(arrangement: ringsLayoutPortrait, content: ringsContent)
        : .init(arrangement: ringsLayoutLandscape, content: ringsContent)
    }
    set {
      if isPortrait {
        ringsLayoutPortrait = newValue.arrangement
      } else {
        ringsLayoutLandscape = newValue.arrangement
      }

      ringsContent = newValue.content
    }
  }
}

enum AppViewAction: Equatable {
  case rings(RingsViewAction)
  case viewTransitionedToPortrait
  case viewTransitionedToLandscape
}

struct AppEnvironment {}

func appViewReducer(state: inout AppViewState, action: AppViewAction, environment _: AppEnvironment) {
  switch action {
  case let .rings(action):
    ringsViewReducer(state: &state.rings, action: action, environment: ringsViewEnvironment)

  case .viewTransitionedToPortrait:
    state.isPortrait = true

  case .viewTransitionedToLandscape:
    state.isPortrait = false
  }
}

let appState = CurrentValueSubject<AppViewState, Never>(AppViewState())
let ringsViewEnvironment = RingsViewEnvironment()

class AppViewController: UIViewController {
  var cancellables: Set<AnyCancellable> = []

  var savedRingsArrangementPortrait = RingsLayout(acentricAxis: .alongLongestDimension, concentricity: 0.0, focus: .period, scaleFactorWhenFullyAcentric: 1.0, scaleFactorWhenFullyConcentric: 1.0)
  var savedRingsArrangementLandscape = RingsLayout(acentricAxis: .alongLongestDimension, concentricity: -1.0, focus: .period, scaleFactorWhenFullyAcentric: 1.0, scaleFactorWhenFullyConcentric: 1.0)

  override func viewDidLoad() {
    super.viewDidLoad()

    appViewReducer(state: &appState.value,
                   action: view.isPortrait
                     ? .viewTransitionedToPortrait
                     : .viewTransitionedToLandscape,
                   environment: AppEnvironment())

    let ringsInput = appState
      .map(\.rings)
      .removeDuplicates()
      .eraseToAnyPublisher()

    ringsInput.map(\.arrangement).removeDuplicates().sink {
      if self.view.isPortrait {
        self.savedRingsArrangementPortrait = $0
      } else {
        self.savedRingsArrangementLandscape = $0
      }
    }
    .store(in: &cancellables)

    let ringsView = RingsView(input: ringsInput)
      .moveTo(view) { ringsView, parentView in
        ringsView.leadingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leadingAnchor)
        ringsView.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor)
        ringsView.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor)
        ringsView.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor)
      }

    ringsView.output
      .sink { action in
        appViewReducer(state: &appState.value, action: .rings(action), environment: AppEnvironment())
      }
      .store(in: &cancellables)
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate { _ in
      appViewReducer(state: &appState.value,
                     action: size.isPortrait
                       ? .viewTransitionedToPortrait
                       : .viewTransitionedToLandscape,
                     environment: AppEnvironment())
    }

    super.viewWillTransition(to: size, with: coordinator)
  }
}
