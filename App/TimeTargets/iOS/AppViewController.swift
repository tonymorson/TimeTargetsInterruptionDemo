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

class AppStore {
  @Published var appState = AppViewState()
  let environment = AppEnvironment()

  func send(_ action: AppViewAction) {
    appReducer(state: &appState, action: action, environment: environment)
  }

  var dataButtonIconImageName: AnyPublisher<String, Never> {
    isShowingData
      .map { $0 ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right" }
      .eraseToAnyPublisher()
  }

  var settings: AnyPublisher<SettingsEditorState?, Never> {
    $appState.map(\.settings)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  var rings: AnyPublisher<RingsViewState, Never> {
    $appState.map(\.rings)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  var isShowingData: AnyPublisher<Bool, Never> {
    $appState
      .removeDuplicates()
      .map(\.isShowingData)
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

    view.tintColor = .systemRed

    let toolbar = makeToolbar(imageName: store.dataButtonIconImageName, parentView: view)
      .moveTo(view) { toolbar, parentView in
        toolbar.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor)
        toolbar.leadingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leadingAnchor)
        toolbar.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor)
        toolbar.heightAnchor.constraint(equalToConstant: 44)
      }

    let bottomMenu = makeMenuButton()
      .moveTo(view) { bottomMenu, parentView in
        bottomMenu.centerXAnchor.constraint(equalTo: parentView.centerXAnchor)
        bottomMenu.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor)
          .reactive(store.isShowingData.map { $0 ? 88 : 0 }.eraseToAnyPublisher())
      }

    if #available(iOS 14, *) {
      bottomMenu.menu = demoMenu
      bottomMenu.showsMenuAsPrimaryAction = true
    } else {
      bottomMenu.addTarget(self, action: #selector(didTapMenuButton(sender:)), for: .touchUpInside)
    }

    let tabBar = UITabBar()
    tabBar.items = [
      UITabBarItem(title: "Today", image: UIImage(systemName: "star.fill"), tag: 0),
      UITabBarItem(title: "Tasks", image: UIImage(systemName: "list.dash"), tag: 1),
      UITabBarItem(title: "Charts", image: UIImage(systemName: "chart.pie.fill"), tag: 2),
    ]

    tabBar.moveTo(view) { tabBar, _ in
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor)
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
      tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 200)
        .reactive(store.isShowingData.map { $0 ? 0 : 200 }.eraseToAnyPublisher())
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
        ringsView.bottomAnchor.constraint(equalTo: bottomMenu.topAnchor, constant: 0)
          .reactive(store.isShowingData.map { $0 ? nil : 0 }.eraseToAnyPublisher())
        ringsView.heightAnchor.constraint(equalToConstant: 150)
          .reactive(store.isShowingData.map { $0 ? 150 : nil }.eraseToAnyPublisher())
      }

    ringsView.output
      .sink { action in
        store.send(.rings(action))
      }
      .store(in: &cancellables)

    store.$appState.map(\.settings)
      .filter { $0 != nil }
      .sink { _ in
        if self.presentedViewController == nil {
          let filteredSettings = store.settings.filter { $0 != nil }.map { $0! }.eraseToAnyPublisher()
          let editor = SettingsEditor(state: filteredSettings)
          editor.onDismiss = { store.send(.settingsEditorDismissed) }
          self.present(editor, animated: true)

          (editor.viewControllers.first)?
            .navigationBarItems(leading: { BarButtonItem(.cancel) { store.send(.settingsEditorDismissed) } })
            .navigationBarItems(trailing: { BarButtonItem(.done) { store.send(.settingsEditorDismissed) } })

          editor.actions.sink { action in
            store.send(.settings(action))
          }
          .store(in: &self.cancellables)
        }
      }
      .store(in: &cancellables)

    store.$appState.map(\.settings)
      .filter { $0 == nil }
      .sink { _ in
        if self.presentedViewController is SettingsEditor {
          self.dismiss(animated: true)
        }
      }
      .store(in: &cancellables)

    let segmentedControl = UISegmentedControl(items: [
      UIAction(title: "Period") { _ in },
      UIAction(title: "Session") { _ in },
      UIAction(title: "Target") { _ in },
    ])
      .moveTo(view) { control, parent in
        control.leadingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.leadingAnchor)
        control.trailingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.trailingAnchor)
        control.topAnchor.constraint(equalTo: ringsView.bottomAnchor, constant: 10)
      }

    store.$appState.sink { state in
      segmentedControl.alpha = state.isShowingData ? 1.0 : 0.0
      segmentedControl.selectedSegmentIndex = 0
    }
    .store(in: &cancellables)
  }

  var demoMenu: UIMenu {
    var menuItems: [UIAction] {
      [
        UIAction(title: "Start Break", image: UIImage(systemName: "arrow.right"), handler: { _ in
          //        viewStore.send(.rings(.ringsTapped(.period)))
        }),
        UIAction(title: "Skip Break", image: UIImage(systemName: "arrow.right.to.line"), handler: { _ in
          //        viewStore.send(.rings(.ringsTapped(.period)))
        }),
      ].reversed()
    }

    return UIMenu(title: "", image: nil, identifier: nil, options: [], children: menuItems)
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate { _ in
      store.send(size.isPortrait
        ? .viewTransitionedToPortrait
        : .viewTransitionedToLandscape)
    }

    super.viewWillTransition(to: size, with: coordinator)
  }

  @objc func didTapMenuButton(sender _: UIButton) {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

    alert.addAction(UIAlertAction(title: "Start Break?", style: .default, handler: { _ in }))
    alert.addAction(UIAlertAction(title: "Skip Break?", style: .default, handler: { _ in }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))

    present(alert, animated: true)
  }
}

private func makeToolbar(imageName: AnyPublisher<String, Never>, parentView: UIView) -> UIStackView {
  let settingsButton = Button(imageSystemName: "gear") {
    store.send(.showSettingsEditorButtonTapped)
  }

  let dataButton = Button(imageSystemName: imageName) {
    parentView.setNeedsLayout()

    UIView.animate(withDuration: 0.35,
                   delay: 0.0,
                   usingSpringWithDamping: 0.8,
                   initialSpringVelocity: 0.3,
                   options: [.allowUserInteraction]) {
      store.send(.showDataButtonTapped)
      parentView.layoutIfNeeded()
    }
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

func makeMenuButton() -> UIButton {
  let button = UIButton(type: .roundedRect)
  button.setTitle("Ready for a break?", for: .normal)
  button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .light).rounded()

  return button
}

extension UIFont {
  func rounded() -> UIFont {
    guard let descriptor = fontDescriptor.withDesign(.rounded) else {
      return self
    }

    return UIFont(descriptor: descriptor, size: pointSize)
  }
}
