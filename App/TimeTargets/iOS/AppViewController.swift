import Combine
import RingsView
import SettingsEditor
import SwiftUIKit
import UIKit

private struct RingsLayoutPair: Equatable {
  public var landscape: RingsViewLayout
  public var portrait: RingsViewLayout

  init(landscape: RingsViewLayout, portrait: RingsViewLayout) {
    self.landscape = landscape
    self.portrait = portrait
  }

  init() {
    landscape = .init(acentricAxis: .alongLongestDimension,
                      concentricity: 1.0,
                      scaleFactorWhenFullyAcentric: 1.0,
                      scaleFactorWhenFullyConcentric: 1.0)

    portrait = .init(acentricAxis: .alongLongestDimension,
                     concentricity: 0.0,
                     scaleFactorWhenFullyAcentric: 1.0,
                     scaleFactorWhenFullyConcentric: 1.0)
  }
}

private enum RingsDisplayMode {
  case ringsOnly
  case ringsAndActivityView

  mutating func toggle() {
    switch self {
    case .ringsOnly: self = .ringsAndActivityView
    case .ringsAndActivityView: self = .ringsOnly
    }
  }
}

private struct AppViewState: Equatable {
  var appSettings: SettingsEditorState?
  var isBestLaidOutInPortraitMode: Bool
  var mainViewDisplayMode: RingsDisplayMode
  var ringsContent: RingsData
  var ringsOnlyLayout: RingsLayoutPair
  var ringsWithActivityViewLayout: RingsViewLayout
  var prominentlyDisplayedRing: RingIdentifier

  init() {
    appSettings = nil
    mainViewDisplayMode = .ringsOnly
    ringsContent = .init()
    ringsOnlyLayout = .init()
    isBestLaidOutInPortraitMode = true
    ringsWithActivityViewLayout = .init(acentricAxis: .alongLongestDimension, concentricity: 1.0, scaleFactorWhenFullyAcentric: 1.0, scaleFactorWhenFullyConcentric: 1.0)
    prominentlyDisplayedRing = .period
  }

  var ringsView: RingsViewState {
    get {
      switch mainViewDisplayMode {
      case .ringsOnly:
        return .init(content: ringsContent,
                     layout: isBestLaidOutInPortraitMode
                       ? ringsOnlyLayout.portrait
                       : ringsOnlyLayout.landscape,
                     prominentRing: prominentlyDisplayedRing)

      case .ringsAndActivityView:
        return .init(content: ringsContent,
                     layout: ringsWithActivityViewLayout,
                     prominentRing: prominentlyDisplayedRing)
      }
    }
    set {
      ringsContent = newValue.content
      prominentlyDisplayedRing = newValue.prominentRing

      switch mainViewDisplayMode {
      case .ringsOnly:
        if isBestLaidOutInPortraitMode {
          ringsOnlyLayout.portrait = newValue.layout
        } else {
          ringsOnlyLayout.landscape = newValue.layout
        }

      case .ringsAndActivityView:
        ringsWithActivityViewLayout = newValue.layout
      }
    }
  }
}

enum AppViewAction: Equatable {
  case settingsEditor(SettingsEditorAction)
  case ringsView(RingsViewAction)
  case settingsEditorDismissed
  case showDataButtonTapped
  case showSettingsEditorButtonTapped
  case mainViewBoundsChanged(Bool)
}

private let store = AppStore()

private class AppStore {
  @Published private var state = AppViewState()
  @Published var receiveAction: AppViewAction?

  var ringsDisplayMode: AnyPublisher<RingsDisplayMode, Never> {
    $state
      .map(\.mainViewDisplayMode)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  var rings: AnyPublisher<RingsViewState, Never> {
    $state
      .map {
        switch $0.mainViewDisplayMode {
        case .ringsOnly:
          return .init(content: $0.ringsContent,
                       layout: $0.isBestLaidOutInPortraitMode
                         ? $0.ringsOnlyLayout.portrait
                         : $0.ringsOnlyLayout.landscape,
                       prominentRing: $0.prominentlyDisplayedRing)

        case .ringsAndActivityView:
          return .init(content: $0.ringsContent,
                       layout: $0.ringsWithActivityViewLayout,
                       prominentRing: $0.prominentlyDisplayedRing)
        }
      }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  var ringsFocus: AnyPublisher<RingIdentifier, Never> {
    $state
      .map(\.prominentlyDisplayedRing)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  var settings: AnyPublisher<SettingsEditorState?, Never> {
    $state
      .map(\.appSettings)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  private var cancellables: Set<AnyCancellable> = []

  init() {
    $receiveAction
      .compactMap { $0 }
      .sink { appReducer(state: &self.state, action: $0) }
      .store(in: &cancellables)
  }
}

private func appReducer(state: inout AppViewState, action: AppViewAction) {
  switch action {
  case let .ringsView(action):
    ringsViewReducer(state: &state.ringsView, action: action)

  case let .settingsEditor(action):
    if let _ = state.appSettings {
      settingsEditorReducer(state: &state.appSettings!, action: action)
    }

  case .showDataButtonTapped:
    state.mainViewDisplayMode.toggle()

  case .showSettingsEditorButtonTapped:
    state.appSettings = .init()

  case .settingsEditorDismissed:
    state.appSettings = nil

  case let .mainViewBoundsChanged(isPortrait):
    state.isBestLaidOutInPortraitMode = isPortrait
  }
}

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
    }

    // Configure tab bar

    view.host(tabBar) { tabBar, host in
      tabBar.leadingAnchor.constraint(equalTo: host.leadingAnchor)
      tabBar.trailingAnchor.constraint(equalTo: host.trailingAnchor)
      tabBar.bottomAnchor.constraint(equalTo: host.layoutMarginsGuide.bottomAnchor)
        .reactive(store.ringsDisplayMode.map { $0 == .ringsAndActivityView ? 0 : 200 }.eraseToAnyPublisher())
      tabBar.heightAnchor.constraint(equalToConstant: 40)
//        .reactive(store.isPortrait.map { $0 ? 49 : 30 }.eraseToAnyPublisher())
    }

    // Configure rings view

    view.host(ringsView) { rings, host in
      rings.leadingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.leadingAnchor)
        .reactive(store.ringsDisplayMode.map { $0 == .ringsAndActivityView ? 20 : 0 }.eraseToAnyPublisher())
      rings.trailingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.trailingAnchor)
        .reactive(store.ringsDisplayMode.map { $0 == .ringsAndActivityView ? -20 : 0 }.eraseToAnyPublisher())
      rings.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor, constant: 0)
      rings.bottomAnchor.constraint(equalTo: bottomMenuPopup.topAnchor)
        .reactive(store.ringsDisplayMode.map { $0 == .ringsAndActivityView ? nil : -20 }.eraseToAnyPublisher())
      rings.heightAnchor.constraint(equalToConstant: 150)
        .reactive(store.ringsDisplayMode.map { $0 == .ringsAndActivityView ? 150 : nil }.eraseToAnyPublisher())
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
            .map(AppViewAction.settingsEditor)
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
      .map(AppViewAction.ringsView)
      .assign(to: &store.$receiveAction)

    return rings
  }()

  private lazy var topAppToolbar: AppToolbar = {
    AppToolbar(frame: .zero)
  }()

  private lazy var bottomMenuPopup: UIView = {
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

    store.ringsFocus
      .map { $0 == .period }
      .map { $0 ? ("Ready for a break?", UIColor.systemRed) : ("Next break at 2.30 PM", .label) }
      .sink { [unowned self] in
        var title = AttributedString($0.0)
        title.font = UIFont.systemFont(ofSize: 19, weight: .light).rounded()
        title.foregroundColor = $0.1
        popup.configuration?.attributedTitle = title
      }
      .store(in: &cancellables)

//    store
//      .bottomMenuAlpha
//      .assign(to: \.alpha, on: button)
//      .store(in: &cancellables)

    store.ringsFocus
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

    let wrapperView = UIView(frame: .zero)
    wrapperView.host(popup) { popup, wrapper in
      popup.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor)
      popup.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor)
//        .reactive(store.bottomMenuOffsetConstraint)
      popup.heightAnchor.constraint(equalTo: wrapper.heightAnchor)
      popup.widthAnchor.constraint(equalTo: wrapper.widthAnchor)
    }

    return wrapperView
  }()

  private lazy var segmentedControl: UISegmentedControl = {
    let segmentedControl = UISegmentedControl(items: ["Period", "Session", "Target"])

    store.ringsDisplayMode
      .map { $0 == .ringsAndActivityView ? 1.0 : 0.0 }
      .removeDuplicates()
      .assign(to: \.alpha, on: segmentedControl)
      .store(in: &cancellables)

    store.ringsFocus
      .map(\.rawValue)
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

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    store.receiveAction = .mainViewBoundsChanged(view.isPortrait)
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { store.receiveAction = .ringsView(.ringsViewTapped(.period)) }
    }
  }

  static var skipBreak: UIAction {
    UIAction(title: "Skip Break",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Skip Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { store.receiveAction = .ringsView(.ringsViewTapped(.period)) }
    }
  }

  static var dismissSettingsEditor: UIAction {
    UIAction(title: "Cancel", discoverabilityTitle: "Cancel") { _ in
      store.receiveAction = .settingsEditorDismissed
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
        button.leadingAnchor.constraint(equalTo: parent.leadingAnchor)
        button.topAnchor.constraint(equalTo: parent.topAnchor)
        button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
      }

    let button = UIButton(configuration: smallButton, primaryAction: .showUserData(view: self))
      .moveTo(self) { button, parent in
        button.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
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
