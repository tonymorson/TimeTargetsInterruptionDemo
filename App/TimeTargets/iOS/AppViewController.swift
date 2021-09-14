import Combine
import RingsView
import SettingsEditor
import SwiftUIKit
import UIKit

let store = AppStore()

struct AppViewState: Equatable {
  var isShowingData: Bool
  var isPortrait: Bool
  var ringsLayoutPortrait: RingsLayout
  var ringsLayoutLandscape: RingsLayout
  var ringsContent: RingsData
  var settings: SettingsEditorState?

  init() {
    isPortrait = true
    isShowingData = false
    ringsLayoutPortrait = RingsLayout(acentricAxis: .alongLongestDimension, concentricity: 0.0, focus: .period, scaleFactorWhenFullyAcentric: 1.0, scaleFactorWhenFullyConcentric: 1.0)
    ringsLayoutLandscape = RingsLayout(acentricAxis: .alongLongestDimension, concentricity: -1.0, focus: .period, scaleFactorWhenFullyAcentric: 1.0, scaleFactorWhenFullyConcentric: 1.0)
    ringsContent = .init()
    settings = nil
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
  case settings(SettingsEditorAction)
  case settingsEditorDismissed
  case showDataButtonTapped
  case showSettingsEditorButtonTapped
  case viewTransitionedToLandscape
  case viewTransitionedToPortrait
}

struct AppEnvironment {}

struct AppStore {
  let appState = CurrentValueSubject<AppViewState, Never>(AppViewState())
  let environment = AppEnvironment()

  func send(_ action: AppViewAction) {
    appReducer(state: &appState.value, action: action, environment: environment)
  }

  var dataButtonIconImageName: AnyPublisher<String, Never> {
    appState.map(\.isShowingData)
      .map { $0 ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right" }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  var settings: AnyPublisher<SettingsEditorState?, Never> {
    appState.map(\.settings)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  var rings: AnyPublisher<RingsViewState, Never> {
    appState.map(\.rings)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }
}

func appReducer(state: inout AppViewState, action: AppViewAction, environment _: AppEnvironment) {
  switch action {
  case let .rings(action):
    ringsViewReducer(state: &state.rings, action: action, environment: ringsViewEnvironment)

  case let .settings(action):
    if let _ = state.settings {
      settingsEditorReducer(state: &state.settings!, action: action, environment: SettingsEditorEnvironment())
    }

  case .viewTransitionedToPortrait:
    state.isPortrait = true

  case .viewTransitionedToLandscape:
    state.isPortrait = false

  case .showDataButtonTapped:
    state.isShowingData.toggle()

  case .showSettingsEditorButtonTapped:
    state.settings = .init()

  case .settingsEditorDismissed:
    state.settings = nil
  }
}

let ringsViewEnvironment = RingsViewEnvironment()

class AppViewController: UIViewController {
  var cancellables: Set<AnyCancellable> = []

  override func viewDidLoad() {
    super.viewDidLoad()

    let toolbar = makeToolbar(imageName: store.dataButtonIconImageName)

    toolbar.moveTo(view) { toolbar, parentView in
      toolbar.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor)
      toolbar.leadingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leadingAnchor)
      toolbar.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor)
      toolbar.heightAnchor.constraint(equalToConstant: 44)
    }

    store.send(view.isPortrait
      ? .viewTransitionedToPortrait
      : .viewTransitionedToLandscape)

    let ringsInput = store.rings

    let ringsView = RingsView(input: ringsInput)
      .moveTo(view) { ringsView, parentView in
        ringsView.leadingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leadingAnchor)
        ringsView.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor)
        ringsView.topAnchor.constraint(equalTo: toolbar.bottomAnchor)
        ringsView.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor)
      }

    ringsView.output
      .sink { action in
        store.send(.rings(action))
      }
      .store(in: &cancellables)

    store.appState.map(\.settings)
      .filter { $0 != nil }
      .sink { _ in
        if self.presentedViewController == nil {
          let filteredSettings = store.settings.filter { $0 != nil }.map { $0! }.eraseToAnyPublisher()
          let editor = SettingsEditor(state: filteredSettings)
          editor.onDismiss = { store.send(.settingsEditorDismissed) }
          self.present(editor, animated: true)

          (editor.viewControllers.first)?
            .navigationBarItems(leading: { UIBarButtonItem(.cancel) { store.send(.settingsEditorDismissed) } })
            .navigationBarItems(trailing: { UIBarButtonItem(.done) { store.send(.settingsEditorDismissed) } })

          editor.actions.sink { action in
            store.send(.settings(action))
          }
          .store(in: &self.cancellables)
        }
      }
      .store(in: &cancellables)

    store.appState.map(\.settings)
      .filter { $0 == nil }
      .sink { _ in
        if self.presentedViewController != nil {
          self.dismiss(animated: true)
        }
      }
      .store(in: &cancellables)
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate { _ in
      store.send(size.isPortrait
        ? .viewTransitionedToPortrait
        : .viewTransitionedToLandscape)
    }

    super.viewWillTransition(to: size, with: coordinator)
  }
}

private func makeToolbar(imageName: AnyPublisher<String, Never>) -> UIStackView {
  let settingsButton = Button(imageSystemName: "gear") {
    store.send(.showSettingsEditorButtonTapped)
  }

  let dataButton = Button(imageSystemName: imageName) {
    store.send(.showDataButtonTapped)
  }

  dataButton.transform = CGAffineTransform(rotationAngle: 90 * .pi / 180)
  settingsButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
  dataButton.widthAnchor.constraint(equalToConstant: 44).isActive = true

  let toolbar = HStack {
    settingsButton
    dataButton
  }

  return toolbar
}
