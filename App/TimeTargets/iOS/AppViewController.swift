import Combine
import RingsView
import SettingsEditor
import SwiftUIKit
import UIKit

struct AppViewState: Equatable {
  struct RingsArrangement: Equatable {
    public var acentricAxis: AcentricLayoutMode
    public var concentricity: CGFloat
    public var scaleFactorWhenFullyAcentric: CGFloat
    public var scaleFactorWhenFullyConcentric: CGFloat

    public init(acentricAxis: AcentricLayoutMode,
                concentricity: CGFloat,
                scaleFactorWhenFullyAcentric: CGFloat,
                scaleFactorWhenFullyConcentric: CGFloat)
    {
      self.acentricAxis = acentricAxis
      self.concentricity = concentricity
      self.scaleFactorWhenFullyAcentric = scaleFactorWhenFullyAcentric
      self.scaleFactorWhenFullyConcentric = scaleFactorWhenFullyConcentric
    }
  }

  var isPortrait: Bool
  var isShowingData: Bool
  var ringsArrangementPortrait: RingsArrangement
  var ringsArrangementLandscape: RingsArrangement
  var ringsContent: RingsData
  var ringFocus: RingSemantic
  var settings: SettingsEditorState?

  init() {
    isPortrait = true
    isShowingData = false
    ringsArrangementPortrait = .init(concentricity: 0.0)
    ringsArrangementLandscape = .init(concentricity: 1.0)
    ringsContent = .init()
    ringFocus = .period
    settings = nil
  }

  var ringsViewLayoutPortrait: RingsViewLayout {
    RingsViewLayout(layout: ringsArrangementPortrait, focus: ringFocus)
  }

  var ringsViewLayoutLandscape: RingsViewLayout {
    RingsViewLayout(layout: ringsArrangementLandscape, focus: ringFocus)
  }

  var ringsViewLayoutDataMode: RingsViewLayout {
    RingsViewLayout(layout: isPortrait ? ringsArrangementPortrait : ringsArrangementLandscape, focus: ringFocus)
  }

  var rings: RingsViewState {
    get {
      if isShowingData {
        return .init(arrangement: ringsViewLayoutDataMode, content: ringsContent)
      }

      return isPortrait
        ? .init(arrangement: ringsViewLayoutPortrait, content: ringsContent)
        : .init(arrangement: ringsViewLayoutLandscape, content: ringsContent)
    }
    set {
      if isPortrait {
        ringsArrangementPortrait = RingsArrangement(layout: newValue.arrangement)
      } else {
        ringsArrangementLandscape = RingsArrangement(layout: newValue.arrangement)
      }
      ringsContent = newValue.content
      ringFocus = newValue.arrangement.focus
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

let store = AppStore()

class AppStore {
  @Published private var state = AppViewState()
  @Published var receiveAction: AppViewAction?

  let environment = AppEnvironment()

  var isShowingData: AnyPublisher<Bool, Never> {
    $state
      .removeDuplicates()
      .map(\.isShowingData)
      .eraseToAnyPublisher()
  }

  var rings: AnyPublisher<RingsViewState, Never> {
    $state.map(\.rings)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  var settings: AnyPublisher<SettingsEditorState?, Never> {
    $state.map(\.settings)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  private var cancellables: Set<AnyCancellable> = []

  init() {
    $receiveAction
      .compactMap { $0 }
      .sink { appReducer(state: &self.state, action: $0, environment: self.environment) }
      .store(in: &cancellables)
  }
}

func appReducer(state: inout AppViewState, action: AppViewAction, environment _: AppEnvironment) {
  switch action {
  case let .rings(action):
    ringsViewReducer(state: &state.rings, action: action, environment: ringsViewEnvironment)

  case let .settings(action):
    if let _ = state.settings {
      settingsEditorReducer(state: &state.settings!, action: action, environment: settingsEditorEnvironment)
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
let settingsEditorEnvironment = SettingsEditorEnvironment()

class AppViewController: UIViewController {
  var cancellables: Set<AnyCancellable> = []

  override func viewDidLoad() {
    super.viewDidLoad()

    view.tintColor = .systemRed

    // Configure top toolbar

    view.host(topAppToolbar) { toolbar, host in
      toolbar.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor)
      toolbar.leadingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.leadingAnchor)
      toolbar.trailingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.trailingAnchor)
      toolbar.heightAnchor.constraint(equalToConstant: 44)
    }

    // Configure bottom menu popup

    view.host(bottomMenuPopup) { popup, host in
      popup.centerXAnchor.constraint(equalTo: host.centerXAnchor)
      popup.bottomAnchor.constraint(equalTo: host.safeAreaLayoutGuide.bottomAnchor)
        .reactive(store.isShowingData.map { $0 ? 88 : -20 }.eraseToAnyPublisher())
    }

    // Configure tab bar

    view.host(tabBar) { tabBar, host in
      tabBar.leadingAnchor.constraint(equalTo: host.leadingAnchor)
      tabBar.trailingAnchor.constraint(equalTo: host.trailingAnchor)
      tabBar.bottomAnchor.constraint(equalTo: host.safeAreaLayoutGuide.bottomAnchor)
        .reactive(store.isShowingData.map { $0 ? 0 : 200 }.eraseToAnyPublisher())
    }

    store.receiveAction = view.isPortrait
      ? .viewTransitionedToPortrait
      : .viewTransitionedToLandscape

    // Configure rings view

    view.host(ringsView) { rings, host in
      rings.leadingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.leadingAnchor)
        .reactive(store.isShowingData.map { $0 ? 20 : 0 }.eraseToAnyPublisher())
      rings.trailingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.trailingAnchor)
        .reactive(store.isShowingData.map { $0 ? -20 : 0 }.eraseToAnyPublisher())
      rings.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor, constant: 0)
      rings.bottomAnchor.constraint(equalTo: bottomMenuPopup.topAnchor)
        .reactive(store.isShowingData.map { $0 ? nil : -20 }.eraseToAnyPublisher())
      rings.heightAnchor.constraint(equalToConstant: 150)
        .reactive(store.isShowingData.map { $0 ? 150 : nil }.eraseToAnyPublisher())
    }

    // Configure settings editor

    store.settings
      .filter { $0 != nil }
      .sink { _ in
        if self.presentedViewController == nil {
          let filteredSettings = store.settings.filter { $0 != nil }.map { $0! }.eraseToAnyPublisher()
          let editor = SettingsEditor(state: filteredSettings)
          editor.onDismiss = { store.receiveAction = .settingsEditorDismissed }
          self.present(editor, animated: true)

          (editor.viewControllers.first)?
            .navigationBarItems(leading: { BarButtonItem(.cancel) { store.receiveAction = .settingsEditorDismissed } })
            .navigationBarItems(trailing: { BarButtonItem(.done) { store.receiveAction = .settingsEditorDismissed } })

          editor.sentActions
            .map(AppViewAction.settings)
            .assign(to: &store.$receiveAction)
        }
      }
      .store(in: &cancellables)

    store.settings
      .filter { $0 == nil }
      .sink { _ in
        if self.presentedViewController is SettingsEditor {
          self.dismiss(animated: true)
        }
      }
      .store(in: &cancellables)

    // Configure segmented control

    segmentedControl
      .moveTo(view) { control, parent in
        control.leadingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.leadingAnchor, constant: 10)
        control.trailingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        control.topAnchor.constraint(equalTo: ringsView.bottomAnchor, constant: 10)
      }
  }

  private lazy var ringsView: RingsView = {
    let rings = RingsView(input: store.rings)

    rings.$sentActions
      .compactMap { $0 }
      .map(AppViewAction.rings)
      .assign(to: &store.$receiveAction)

    return rings
  }()

  private lazy var topAppToolbar: AppToolbar = {
    AppToolbar(frame: .zero)
  }()

  private lazy var bottomMenuPopup: UIButton = {
    var configuration = UIButton.Configuration.gray()
    configuration.cornerStyle = .dynamic
    configuration.baseForegroundColor = UIColor.systemRed
    configuration.baseBackgroundColor = .clear
    configuration.buttonSize = .medium

    configuration.titlePadding = 4
    configuration.titleAlignment = .center

    let button = UIButton(configuration: configuration)
    button.tintColor = .label
    button.showsMenuAsPrimaryAction = true

    let popup = button

    store.rings
      .map(\.arrangement.focus)
      .map { $0 == .period }
      .map { $0 ? ("Ready for a break?", UIColor.systemRed) : ("Next break at 2.30 PM", .label) }
      .sink { [unowned self] in
        var title = AttributedString($0.0)
        title.font = UIFont.systemFont(ofSize: 19, weight: .light).rounded()
        title.foregroundColor = $0.1
        popup.configuration?.attributedTitle = title
      }
      .store(in: &cancellables)

    store.rings
      .map(\.arrangement.focus)
      .map { $0 == .period }
      .map { $0 ? ("You have worked 22 minutes taking 3 breaks so far", UIColor.secondaryLabel) : ("Next break at 2.30PM", .label) }
      .sink {
        var title = AttributedString($0.0)
        title.font = UIFont.systemFont(ofSize: 13, weight: .light)
        title.foregroundColor = $0.1
//        bottomMenu.configuration?.attributedSubtitle = title
      }
      .store(in: &cancellables)

    popup.menu = demoMenu
    popup.showsMenuAsPrimaryAction = true

    return popup
  }()

  private lazy var segmentedControl: UISegmentedControl = {
    let segmentedControl = UISegmentedControl(items: [UIAction.selectPeriodRing,
                                                      .selectSessionRing,
                                                      .selectTargetRing]
    )

    store.isShowingData
      .map { $0 ? 1.0 : 0.0 }
      .assign(to: \.alpha, on: segmentedControl)
      .store(in: &cancellables)

    store.rings
      .map(\.arrangement.focus.rawValue)
      .removeDuplicates()
      .assign(to: \.selectedSegmentIndex, on: segmentedControl)
      .store(in: &cancellables)

    return segmentedControl
  }()

  private lazy var tabBar: UITabBar = {
    let tabBar = UITabBar()
    tabBar.items = [
      UITabBarItem(title: "Today", image: UIImage(systemName: "star.fill"), tag: 0),
      UITabBarItem(title: "Tasks", image: UIImage(systemName: "list.dash"), tag: 1),
      UITabBarItem(title: "Charts", image: UIImage(systemName: "chart.pie.fill"), tag: 2),
    ]

    tabBar.selectedItem = tabBar.items?[0]

    return tabBar
  }()

  private var demoMenu: UIMenu {
    var menuItems: [UIAction] {
      [
        .startBreak,
        .skipBreak,
      ]
      .reversed()
    }

    return UIMenu(children: menuItems)
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate { _ in
      store.receiveAction = size.isPortrait
        ? .viewTransitionedToPortrait
        : .viewTransitionedToLandscape
    }

    super.viewWillTransition(to: size, with: coordinator)
  }
}

extension UIFont {
  func rounded() -> UIFont {
    guard let descriptor = fontDescriptor.withDesign(.rounded) else {
      return self
    }

    return UIFont(descriptor: descriptor, size: pointSize)
  }
}

extension UIAction {
  static var startBreak: UIAction {
    UIAction(title: "Start Break",
             image: UIImage(systemName: "arrow.right"),
             discoverabilityTitle: "Start Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { store.receiveAction = .rings(.ringsTapped(.period)) }
    }
  }

  static var skipBreak: UIAction {
    UIAction(title: "Skip Break",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Skip Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { store.receiveAction = .rings(.ringsTapped(.period)) }
    }
  }

  static var dismissSettingsEditor: UIAction {
    UIAction(title: "Cancel", discoverabilityTitle: "Cancel") { _ in
      store.receiveAction = .settingsEditorDismissed
    }
  }

  static var selectPeriodRing: UIAction {
    UIAction(title: "Period", discoverabilityTitle: "Select Period Ring") { _ in
      store.receiveAction = .rings(.ringSelected(.period))
    }
  }

  static var selectSessionRing: UIAction {
    UIAction(title: "Session", discoverabilityTitle: "Select Session Ring") { _ in
      store.receiveAction = .rings(.ringSelected(.session))
    }
  }

  static var selectTargetRing: UIAction {
    UIAction(title: "Target", discoverabilityTitle: "Select Today Ring") { _ in
      store.receiveAction = .rings(.ringSelected(.target))
    }
  }

  static var showSettingsEditor: UIAction {
    UIAction(image: UIImage(systemName: "gear"), discoverabilityTitle: "Show Settings") { _ in
      store.receiveAction = .showSettingsEditorButtonTapped
    }
  }

  static func showUserData(view: UIView) -> UIAction {
    UIAction(image: UIImage(systemName: "arrow.down.right.and.arrow.up.left"),
             discoverabilityTitle: "Show User Data") { _ in
      view.superview?.setNeedsLayout()
      UIView.animate(withDuration: 0.4,
                     delay: 0.0,
                     usingSpringWithDamping: 0.9,
                     initialSpringVelocity: 0.7,
                     options: [.allowUserInteraction]) {
        store.receiveAction = .showDataButtonTapped
        view.superview?.layoutIfNeeded()
      }
    }
  }
}

final class AppToolbar: UIView {
  override init(frame _: CGRect) {
    super.init(frame: .zero)

    var smallButton = UIButton.Configuration.plain()
    smallButton.buttonSize = .small

    UIButton(configuration: smallButton, primaryAction: .showSettingsEditor)
      .moveTo(self) { button, parent in
        button.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 00)
        button.topAnchor.constraint(equalTo: parent.topAnchor)
        button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
      }

    let button = UIButton(configuration: smallButton, primaryAction: .showUserData(view: self))
      .moveTo(self) { button, parent in
        button.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -00)
        button.topAnchor.constraint(equalTo: parent.topAnchor)
        button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
      }

    button.transform = CGAffineTransform(rotationAngle: 90 * .pi / 180)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension AppViewState.RingsArrangement {
  init(layout: RingsViewLayout) {
    acentricAxis = layout.acentricAxis
    concentricity = layout.concentricity
    scaleFactorWhenFullyAcentric = layout.scaleFactorWhenFullyAcentric
    scaleFactorWhenFullyConcentric = layout.scaleFactorWhenFullyConcentric
  }

  init(concentricity: CGFloat) {
    acentricAxis = .alongLongestDimension
    self.concentricity = concentricity
    scaleFactorWhenFullyAcentric = 1.0
    scaleFactorWhenFullyConcentric = 1.0
  }
}

extension RingsViewLayout {
  init(layout: AppViewState.RingsArrangement, focus: RingSemantic) {
    self.init(acentricAxis: layout.acentricAxis,
              concentricity: layout.concentricity,
              focus: focus,
              scaleFactorWhenFullyAcentric: layout.scaleFactorWhenFullyAcentric,
              scaleFactorWhenFullyConcentric: layout.scaleFactorWhenFullyConcentric)
  }
}
