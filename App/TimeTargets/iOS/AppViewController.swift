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

private enum DisplayMode {
  case singleColumn
  case doubleColumn

  mutating func toggle() {
    switch self {
    case .singleColumn: self = .doubleColumn
    case .doubleColumn: self = .singleColumn
    }
  }
}

enum TabIdentifier {
  case today, tasks, charts
}

private struct AppViewState: Equatable {
  var appSettings: SettingsEditorState?
  var columnDisplayMode: DisplayMode
  var preferredRingsLayoutInSingleColumnMode: RingsLayoutPair
  var preferredRingsLayoutInDoubleColumnModeMode: RingsViewLayout
  var prominentlyDisplayedRing: RingIdentifier
  var ringsContent: RingsData
  var selectedDataTab: TabIdentifier

  var dataHeadlineContent: (String, String)? {
    switch columnDisplayMode {
    case .singleColumn:
      return nil
    case .doubleColumn:
      switch selectedDataTab {
      case .today:
        return ("Today", "5 Events")
      case .tasks:
        return ("Task Inventory", "3 of 5 remaining")
      case .charts:
        return ("Productivity", "Charts")
      }
    }
  }

  init() {
    appSettings = nil
    columnDisplayMode = .singleColumn
    ringsContent = .init()
    preferredRingsLayoutInSingleColumnMode = .init()
    preferredRingsLayoutInDoubleColumnModeMode = .init(acentricAxis: .alwaysVertical,
                                                       concentricity: 1.0,
                                                       scaleFactorWhenFullyAcentric: 1.0,
                                                       scaleFactorWhenFullyConcentric: 1.0)
    prominentlyDisplayedRing = .period
    selectedDataTab = .today

    preferredRingsLayoutInSingleColumnMode = .init()

    ringsViewDataModeRegular = .init(content: ringsContent, layout: preferredRingsLayoutInDoubleColumnModeMode, prominentRing: prominentlyDisplayedRing)
  }

  var ringsViewOnlyPortrait: RingsViewState {
    .init(content: ringsContent,
          layout: preferredRingsLayoutInSingleColumnMode.portrait,
          prominentRing: prominentlyDisplayedRing)
  }

  var ringsViewOnlyLandscape: RingsViewState {
    .init(content: ringsContent,
          layout: preferredRingsLayoutInSingleColumnMode.landscape,
          prominentRing: prominentlyDisplayedRing)
  }

  var ringsViewDataModeCompact: RingsViewState {
    .init(content: ringsContent, layout: .init(acentricAxis: .alongLongestDimension, concentricity: 0.0, scaleFactorWhenFullyAcentric: 1.0, scaleFactorWhenFullyConcentric: 1.0), prominentRing: prominentlyDisplayedRing)
  }

  var ringsViewDataModeRegular: RingsViewState
}

enum AppViewAction: Equatable {
  case settingsEditor(SettingsEditorAction)
  case ringsView(RingsViewAction, whilePortrait: Bool)
  case settingsEditorDismissed
  case showDataButtonTapped
  case showSettingsEditorButtonTapped
  case tabBarItemTapped(TabIdentifier)
}

private let store = AppStore()

private class AppStore {
  @Published var state = AppViewState()
  @Published var receiveAction: AppViewAction?

  var ringsDisplayMode: AnyPublisher<DisplayMode, Never> {
    $state
      .map(\.columnDisplayMode)
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
  case let .ringsView(action, whilePortrait):
    switch action {
    case let .acentricRingsPinched(scaleFactor: scaleFactor):
      switch state.columnDisplayMode {
      case .singleColumn:
        if whilePortrait {
          state.preferredRingsLayoutInSingleColumnMode.portrait.scaleFactorWhenFullyAcentric = scaleFactor
        } else {
          state.preferredRingsLayoutInSingleColumnMode.landscape.scaleFactorWhenFullyAcentric = scaleFactor
        }
      case .doubleColumn:
        state.ringsViewDataModeRegular.layout.scaleFactorWhenFullyAcentric = scaleFactor
      }

    case let .concentricRingsPinched(scaleFactor: scaleFactor):
      switch state.columnDisplayMode {
      case .singleColumn:
        if whilePortrait {
          state.preferredRingsLayoutInSingleColumnMode.portrait.scaleFactorWhenFullyConcentric = scaleFactor
        } else {
          state.preferredRingsLayoutInSingleColumnMode.landscape.scaleFactorWhenFullyConcentric = scaleFactor
        }
      case .doubleColumn:
        state.ringsViewDataModeRegular.layout.scaleFactorWhenFullyConcentric = scaleFactor
      }

    case .concentricRingsTappedInColoredBandsArea:
      switch state.prominentlyDisplayedRing {
      case .period: state.prominentlyDisplayedRing = .session
      case .session: state.prominentlyDisplayedRing = .target
      case .target: state.prominentlyDisplayedRing = .period
      }

    case let .ringConcentricityDragged(concentricity: concentricity):
      switch state.columnDisplayMode {
      case .singleColumn:
        if whilePortrait {
          state.preferredRingsLayoutInSingleColumnMode.portrait.concentricity = concentricity
        } else {
          state.preferredRingsLayoutInSingleColumnMode.landscape.concentricity = concentricity
        }
      case .doubleColumn:
        state.ringsViewDataModeRegular.layout.concentricity = concentricity
      }

    case .ringsViewTapped(.some):

      if state.ringsContent.period.color == .systemGray2 || state.ringsContent.period.color == .lightGray {
        state.ringsContent.period.color = .systemRed
        state.ringsContent.session.color = .systemGreen
        state.ringsContent.target.color = .systemYellow

        state.ringsContent.period.trackColor = .systemGray4
        state.ringsContent.session.trackColor = .systemGray4
        state.ringsContent.target.trackColor = .systemGray4

      } else {
        state.ringsContent.period.color = .systemGray2
        state.ringsContent.session.color = .systemGray2
        state.ringsContent.target.color = .systemGray2

        state.ringsContent.period.trackColor = UIColor.systemGray5
        state.ringsContent.session.trackColor = .systemGray5
        state.ringsContent.target.trackColor = .systemGray5
      }
    case .ringsViewTapped(.none):
      break
    }

  case let .settingsEditor(action):
    if let _ = state.appSettings {
      settingsEditorReducer(state: &state.appSettings!, action: action)
    }

  case .showDataButtonTapped:
    state.columnDisplayMode.toggle()

  case .showSettingsEditorButtonTapped:
    state.appSettings = .init()

  case .settingsEditorDismissed:
    state.appSettings = nil

  case let .tabBarItemTapped(tab):
    state.selectedDataTab = tab
  }
}

class AppViewController: UIViewController {
  var cancellables: Set<AnyCancellable> = []

  override func viewDidLoad() {
    super.viewDidLoad()

    view.tintColor = .systemRed

    // Configure top toolbar

    view.host(topAppToolbar) { toolbar, host in
      toolbar.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor, constant: 10)
      toolbar.leadingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.leadingAnchor)
      toolbar.trailingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.trailingAnchor)
    }

    // Configure bottom menu popup

    view.host(bottomMenuPopup)

    // Configure tab bar

    view.host(tabBar)

    // Configure rings view

    view.host(ringsView)

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

    store.$state
      .map(\.columnDisplayMode)
      .map { $0 == .doubleColumn &&
        !(self.view.isPortrait &&
          self.traitCollection.horizontalSizeClass == .compact &&
          self.traitCollection.verticalSizeClass == .regular)
      }
      .removeDuplicates()
      .sink { shouldShow in
        self.topAppToolbar.isShowingExtraButton(isShowing: shouldShow)
      }
      .store(in: &cancellables)

    view.host(activityLogHeading)
    view.host(activityLog)

    store.$state
      .map(\.columnDisplayMode)
      .map { $0 == .doubleColumn && !(self.view.isPortrait && self.traitCollection.horizontalSizeClass == .compact && self.traitCollection.verticalSizeClass == .regular) }
      .removeDuplicates()
      .sink { shouldShow in
        self.topAppToolbar.isShowingExtraButton(isShowing: shouldShow)
      }
      .store(in: &cancellables)

    store.$state.map { state -> CGFloat in
      (state.columnDisplayMode == .doubleColumn) && self.view.isPortrait && self.traitCollection.horizontalSizeClass == .compact ? 1.0 : 0.0
    }
    .assign(to: \.alpha, on: tabBar)
    .store(in: &cancellables)

    store.$state.sink { [weak self] in
      guard let self = self else { return }
      let isShowingData = $0.columnDisplayMode == .doubleColumn

      self.noShowDataLayoutMode = self.traitCollection.horizontalSizeClass == .compact
        ? self.singleColumnRingsOnly
        : self.singleColumnRingsOnly

      let x = $0.selectedDataTab == .today ? self.doubleColumnRingsLeft : self.doubleColumnRingsRight
      self.showDataLayoutMode = self.traitCollection.horizontalSizeClass == .compact
        ? self.view.isPortrait ? self.compactWidthLayout2 : x
        : x

      NSLayoutConstraint.deactivate(self.singleColumnRingsOnly)
      NSLayoutConstraint.deactivate(self.compactWidthLayout)
      NSLayoutConstraint.deactivate(self.compactWidthLayout2)
      NSLayoutConstraint.deactivate(self.normalWidthLayout)
      NSLayoutConstraint.deactivate(self.doubleColumnRingsLeft)
      NSLayoutConstraint.deactivate(self.doubleColumnRingsRight)

      if isShowingData {
        NSLayoutConstraint.activate(self.showDataLayoutMode)
      } else {
        NSLayoutConstraint.activate(self.singleColumnRingsOnly)
      }
    }
    .store(in: &cancellables)
  }

  private lazy var ringsView: RingsView = {
    let storeRingsOutput = store.$state
      .map { appState -> RingsViewState in

        if appState.columnDisplayMode == .doubleColumn {
          if self.view.isPortrait, self.traitCollection.horizontalSizeClass == .compact {
            return appState.ringsViewDataModeCompact
          } else {
            return appState.ringsViewDataModeRegular
          }
        }

        if self.view.isPortrait {
          return appState.ringsViewOnlyPortrait
        } else {
          return appState.ringsViewOnlyLandscape
        }
      }
      .removeDuplicates()
      .eraseToAnyPublisher()

    let rings = RingsView(input: storeRingsOutput)

    rings.$sentActions
      .compactMap { $0 }
      .map { AppViewAction.ringsView($0, whilePortrait: self.view.isPortrait) }
//      .map(AppViewAction.ringsView)
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

  private lazy var tabBar: FixedTabBar = {
    let tabBar = FixedTabBar()
    tabBar.items = [
      UITabBarItem(title: "Today", image: UIImage(systemName: "star.fill"), tag: 0),
      UITabBarItem(title: "Tasks", image: UIImage(systemName: "list.dash"), tag: 1),
      UITabBarItem(title: "Charts", image: UIImage(systemName: "chart.pie.fill"), tag: 2),
    ]

    tabBar.isTranslucent = true
    tabBar.backgroundColor = .systemBackground
    tabBar.selectedItem = tabBar.items?[0]

    tabBar.delegate = self

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

    // Nudge the store to force some output so the view gets a change to re-render it's layout if needed
    // after a view bounds or traits change. This helps us avoid sending view state back into the store
    // forcing the view to interpret the best layout for it's orientation and size and not the store.
    store.receiveAction = .tabBarItemTapped(store.state.selectedDataTab)
  }

  private lazy var activityLog: ActivityLog = {
    ActivityLog(frame: .zero)
  }()

  private lazy var activityLogHeading: ActivityLogHeading = {
    ActivityLogHeading(frame: .zero, input: store.$state.map(\.dataHeadlineContent).compactMap { $0 }.eraseToAnyPublisher())
  }()

  var noShowDataLayoutMode: [NSLayoutConstraint] = []
  var showDataLayoutMode: [NSLayoutConstraint] = []

  lazy var singleColumnRingsOnly: [NSLayoutConstraint] = {
    [
      ringsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      ringsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      ringsView.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor),
      ringsView.bottomAnchor.constraint(equalTo: bottomMenuPopup.topAnchor),

      bottomMenuPopup.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      bottomMenuPopup.centerXAnchor.constraint(equalTo: ringsView.centerXAnchor),

      activityLogHeading.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor, constant: 20),
      activityLogHeading.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 1400),
      activityLogHeading.trailingAnchor.constraint(equalTo: ringsView.leadingAnchor, constant: 1400),

      activityLog.topAnchor.constraint(equalTo: activityLogHeading.bottomAnchor),
      activityLog.leadingAnchor.constraint(equalTo: activityLogHeading.leadingAnchor),
      activityLog.trailingAnchor.constraint(equalTo: activityLogHeading.trailingAnchor),

      tabBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 200),
    ]
  }()

  lazy var compactWidthLayout: [NSLayoutConstraint] = {
    [
      ringsView.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor),
      ringsView.heightAnchor.constraint(equalToConstant: 150),
//      ringsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      ringsView.widthAnchor.constraint(equalToConstant: 150),

      bottomMenuPopup.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 200),
      bottomMenuPopup.centerXAnchor.constraint(equalTo: view.centerXAnchor),

      activityLogHeading.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor),
      activityLogHeading.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      activityLogHeading.trailingAnchor.constraint(equalTo: ringsView.leadingAnchor, constant: -20),

      activityLog.topAnchor.constraint(equalTo: ringsView.bottomAnchor, constant: 20),
      activityLog.leadingAnchor.constraint(equalTo: ringsView.leadingAnchor, constant: 20),
      activityLog.trailingAnchor.constraint(equalTo: activityLogHeading.trailingAnchor, constant: -20),
      activityLog.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ]
  }()

  lazy var compactWidthLayout2: [NSLayoutConstraint] = {
    [
      ringsView.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor, constant: 10),
      ringsView.heightAnchor.constraint(equalToConstant: 160),
      ringsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      ringsView.widthAnchor.constraint(equalToConstant: 160),

      bottomMenuPopup.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 200),
      bottomMenuPopup.centerXAnchor.constraint(equalTo: view.centerXAnchor),

      activityLogHeading.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor, constant: 20),
      activityLogHeading.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      activityLogHeading.leadingAnchor.constraint(equalTo: ringsView.trailingAnchor, constant: 20),

      activityLog.topAnchor.constraint(equalTo: ringsView.bottomAnchor, constant: 20),
      activityLog.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      activityLog.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      activityLog.bottomAnchor.constraint(equalTo: tabBar.topAnchor),

//      bottomMenuPopup.leadingAnchor.constraint(equalTo: activityLogHeading.leadingAnchor),
//      bottomMenuPopup.bottomAnchor.constraint(equalTo: activityLog.topAnchor, constant: -50),

      tabBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ]
  }()

  lazy var doubleColumnRingsLeft: [NSLayoutConstraint] = {
    [
      ringsView.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor, constant: 20),
      ringsView.bottomAnchor.constraint(equalTo: bottomMenuPopup.topAnchor, constant: -20),
      ringsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      ringsView.widthAnchor.constraint(equalToConstant: view.bounds.width / 2.75),

      bottomMenuPopup.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      bottomMenuPopup.centerXAnchor.constraint(equalTo: ringsView.centerXAnchor),

      activityLogHeading.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor, constant: 20),
      activityLogHeading.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      activityLogHeading.leadingAnchor.constraint(equalTo: ringsView.trailingAnchor, constant: 40),

      activityLog.topAnchor.constraint(equalTo: activityLogHeading.bottomAnchor, constant: 10),
      activityLog.leadingAnchor.constraint(equalTo: activityLogHeading.leadingAnchor),
      activityLog.trailingAnchor.constraint(equalTo: activityLogHeading.trailingAnchor),

      tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 80),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    ]
  }()

  lazy var doubleColumnRingsRight: [NSLayoutConstraint] = {
    [
      ringsView.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor, constant: 20),
      ringsView.bottomAnchor.constraint(equalTo: bottomMenuPopup.topAnchor, constant: -20),
      ringsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      ringsView.widthAnchor.constraint(equalToConstant: view.bounds.width / 2.75),

      bottomMenuPopup.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      bottomMenuPopup.centerXAnchor.constraint(equalTo: ringsView.centerXAnchor),

      activityLogHeading.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor, constant: 20),
      activityLogHeading.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 40),
      activityLogHeading.trailingAnchor.constraint(equalTo: ringsView.leadingAnchor, constant: -20),

      activityLog.topAnchor.constraint(equalTo: activityLogHeading.bottomAnchor, constant: 10),
      activityLog.leadingAnchor.constraint(equalTo: activityLogHeading.leadingAnchor),
      activityLog.trailingAnchor.constraint(equalTo: activityLogHeading.trailingAnchor),

      tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 80),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    ]
  }()

  lazy var normalWidthLayout: [NSLayoutConstraint] = {
    [
      ringsView.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor),
      ringsView.bottomAnchor.constraint(equalTo: bottomMenuPopup.topAnchor, constant: -20),
      ringsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      ringsView.widthAnchor.constraint(equalToConstant: view.bounds.width / 3.5),

      bottomMenuPopup.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      bottomMenuPopup.centerXAnchor.constraint(equalTo: ringsView.centerXAnchor),

      activityLogHeading.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor),
      activityLogHeading.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      activityLogHeading.trailingAnchor.constraint(equalTo: ringsView.leadingAnchor, constant: -40),

      activityLog.topAnchor.constraint(equalTo: activityLogHeading.bottomAnchor, constant: 40),
      activityLog.leadingAnchor.constraint(equalTo: activityLogHeading.leadingAnchor),
      activityLog.trailingAnchor.constraint(equalTo: activityLogHeading.trailingAnchor),
    ]
  }()
}

extension AppViewController: UITabBarDelegate {
  func tabBar(_: UITabBar, didSelect item: UITabBarItem) {
    switch item.tag {
    case 0: store.receiveAction = .tabBarItemTapped(.today)
    case 1: store.receiveAction = .tabBarItemTapped(.tasks)
    case 2: store.receiveAction = .tabBarItemTapped(.charts)
    default: break
    }
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { store.receiveAction = .ringsView(.ringsViewTapped(.period), whilePortrait: true) }
    }
  }

  static var skipBreak: UIAction {
    UIAction(title: "Skip Break",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Skip Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { store.receiveAction = .ringsView(.ringsViewTapped(.period), whilePortrait: true) }
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

  static func showCharts(view: UIView) -> UIAction {
    UIAction(image: UIImage(systemName: "chart.pie"),
             discoverabilityTitle: "Show User Data") { _ in
      view.superview?.setNeedsLayout()
      UIView.animate(withDuration: 0.4,
                     delay: 0.0,
                     usingSpringWithDamping: 0.9,
                     initialSpringVelocity: 0.7,
                     options: [.allowUserInteraction]) {
        store.receiveAction = .tabBarItemTapped(.charts)
        view.superview?.layoutIfNeeded()
      }
    }
  }

  static func showTasks(view: UIView) -> UIAction {
    UIAction(image: UIImage(systemName: "list.dash"),
             discoverabilityTitle: "Show User Data") { _ in
      view.superview?.setNeedsLayout()
      UIView.animate(withDuration: 0.4,
                     delay: 0.0,
                     usingSpringWithDamping: 0.9,
                     initialSpringVelocity: 0.7,
                     options: [.allowUserInteraction]) {
        store.receiveAction = .tabBarItemTapped(.tasks)
        view.superview?.layoutIfNeeded()
      }
    }
  }

  static func showToday(view: UIView) -> UIAction {
    UIAction(image: UIImage(systemName: "star"),
             discoverabilityTitle: "Show User Data") { _ in
      view.superview?.setNeedsLayout()
      UIView.animate(withDuration: 0.4,
                     delay: 0.0,
                     usingSpringWithDamping: 0.9,
                     initialSpringVelocity: 0.7,
                     options: [.allowUserInteraction]) {
        store.receiveAction = .tabBarItemTapped(.today)
        view.superview?.layoutIfNeeded()
      }
    }
  }
}

final class AppToolbar: UIView {
  override init(frame _: CGRect) {
    super.init(frame: .zero)

    var todayButton: UIButton
    var tasksButton: UIButton
    var chartsButton: UIButton

    var smallButton = UIButton.Configuration.plain()
    smallButton.buttonSize = .small

    UIButton(configuration: smallButton, primaryAction: .showSettingsEditor)
      .moveTo(self) { button, parent in
        button.leadingAnchor.constraint(equalTo: parent.leadingAnchor)
        button.topAnchor.constraint(equalTo: parent.topAnchor)
        button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
      }

    let showUserDataButton = UIButton(configuration: smallButton, primaryAction: .showUserData(view: self))
      .moveTo(self) { button, parent in
        button.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
        button.topAnchor.constraint(equalTo: parent.topAnchor)
        button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
      }

    showUserDataButton.backgroundColor = .systemRed.darker!

    chartsButton = UIButton(configuration: smallButton, primaryAction: .showCharts(view: self))
      .moveTo(self) { button, parent in
        button.trailingAnchor.constraint(equalTo: showUserDataButton.leadingAnchor)
        button.topAnchor.constraint(equalTo: parent.topAnchor)
        button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
      }

    tasksButton = UIButton(configuration: smallButton, primaryAction: .showTasks(view: self))
      .moveTo(self) { button, parent in
        button.trailingAnchor.constraint(equalTo: chartsButton.leadingAnchor)
        button.topAnchor.constraint(equalTo: parent.topAnchor)
        button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
      }

    todayButton = UIButton(configuration: smallButton, primaryAction: .showToday(view: self))
      .moveTo(self) { button, parent in
        button.trailingAnchor.constraint(equalTo: tasksButton.leadingAnchor)
        button.topAnchor.constraint(equalTo: parent.topAnchor)
        button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
      }

    todayButton.tag = 1001
    tasksButton.tag = 1002
    chartsButton.tag = 1003

    showUserDataButton.transform = CGAffineTransform(rotationAngle: 90 * .pi / 180)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func isShowingExtraButton(isShowing: Bool) {
    viewWithTag(1001)?.alpha = isShowing ? 1.0 : 0.0
    viewWithTag(1002)?.alpha = isShowing ? 1.0 : 0.0
    viewWithTag(1003)?.alpha = isShowing ? 1.0 : 0.0
  }
}

final class ActivityLog: UIView {
  private lazy var segmentedControl: UISegmentedControl = {
    let segmentedControl = UISegmentedControl(items: ["Activity", "Tasks", "Interruptions"]
    )

    return segmentedControl
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    host(segmentedControl) { control, parent in
      control.leadingAnchor.constraint(equalTo: parent.leadingAnchor)
      control.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
      control.topAnchor.constraint(equalTo: topAnchor)
    }

    let logEntry = UILabel(frame: .zero)
    logEntry.text = "2:30 PM  Work Interrupted by phone call"
    logEntry.font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: nil).rounded()

    host(logEntry) { logEntry, parent in
      logEntry.leadingAnchor.constraint(equalTo: parent.leadingAnchor)
//        logEntry.trailingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.trailingAnchor)
      logEntry.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20)
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class ActivityLogHeading: UIView {
  var cancellables: Set<AnyCancellable> = []

  init(frame: CGRect, input: AnyPublisher<(String, String), Never>) {
    super.init(frame: frame)

    let title = UILabel(frame: .zero)
    title.text = "Today's Activities"
    title.font = UIFont.preferredFont(forTextStyle: .largeTitle, compatibleWith: nil).rounded()
    title.adjustsFontSizeToFitWidth = true
    title.textAlignment = .left

    host(title) { title, parent in
      title.leadingAnchor.constraint(equalTo: parent.leadingAnchor)
      title.topAnchor.constraint(equalTo: parent.topAnchor, constant: 0)
      title.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
    }

//    let subtitle = UILabel(frame: .zero)
//    subtitle.text = "2 interruptions"
//    subtitle.font = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: nil).rounded()
//    subtitle.textColor = .secondaryLabel
//
//    host(subtitle) { control, parent in
//      control.leadingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.leadingAnchor, constant: 10)
//      control.trailingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.trailingAnchor, constant: -10)
//      control.topAnchor.constraint(equalTo: title.bottomAnchor)
//    }

    let subtitle = UILabel(frame: .zero)
    subtitle.text = "5 Events"
    subtitle.font = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: nil).rounded()
    subtitle.textColor = .systemRed
    subtitle.textAlignment = .left

    host(subtitle) { subtitle, _ in
      subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor)
      subtitle.topAnchor.constraint(equalTo: title.bottomAnchor)
      subtitle.trailingAnchor.constraint(equalTo: trailingAnchor)
      subtitle.bottomAnchor.constraint(equalTo: bottomAnchor)
    }

    input.sink { details in
      title.text = details.0
      subtitle.text = details.1
    }
    .store(in: &cancellables)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// https://gist.github.com/calt/7ea29a65b440c2aa8a1a
final class FixedTabBar: UITabBar {
  override func sizeThatFits(_ size: CGSize) -> CGSize {
    var sizeThatFits = super.sizeThatFits(size)

    sizeThatFits.height = 120

    return sizeThatFits
  }
}
