import Combine
import RingsPopupMenu
import RingsView
import SettingsEditor
import SwiftUIKit
import Timeline
import TimelineReports
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
  var currentTick: Int
  var preferredRingsLayoutInSingleColumnMode: RingsLayoutPair
  var preferredRingsLayoutInDoubleColumnModeMode: RingsViewLayout
  var prominentlyDisplayedRing: RingIdentifier
  var selectedDataTab: TabIdentifier
  var timeline: Timeline

  init() {
    appSettings = nil
    columnDisplayMode = .singleColumn
    preferredRingsLayoutInSingleColumnMode = .init()
    preferredRingsLayoutInDoubleColumnModeMode = .init(acentricAxis: .alwaysVertical,
                                                       concentricity: 1.0,
                                                       scaleFactorWhenFullyAcentric: 1.0,
                                                       scaleFactorWhenFullyConcentric: 1.0)
    prominentlyDisplayedRing = .period
    selectedDataTab = .today

    preferredRingsLayoutInSingleColumnMode = .init()

    ringsViewDataModeRegular = .init(content: .init(),
                                     layout: preferredRingsLayoutInDoubleColumnModeMode,
                                     prominentRing: prominentlyDisplayedRing)

    currentTick = 0
    timeline = .init()
  }

  var report: Report {
    .init(workPattern: timeline.periods,
          dailyTarget: timeline.dailyTarget,
          tick: currentTick)
  }

  var popupMenuItems: [UIAction] {
    let isCountingDown = timeline.countdown.isCountingDown(at: currentTick)
    let isWorkTime = report.currentPeriod.isWorkPeriod
    let isAtStartOfPeriod = report.currentPeriod.firstTick == report.tick

    switch (isCountingDown, isWorkTime, isAtStartOfPeriod) {
    case (true, true, true): return [.pauseWorkPeriod, .skipToNextBreak]
    case (true, true, false): return [.pauseWorkPeriod, .skipToNextBreak, .restartWorkPeriod]
    case (true, false, true): return [.pauseBreak, .skipBreak]
    case (true, false, false): return [.pauseBreak, .skipBreak, .restartBreak]
    case (false, true, true): return [.startWorkPeriod, .skipToNextBreak]
    case (false, true, false): return [.resumeWorkPeriod, .skipToNextBreak, .restartWorkPeriod]
    case (false, false, true): return [.startBreak, .skipBreak]
    case (false, false, false): return [.resumeBreak, .skipToNextWorkPeriod, .restartBreak]
    }
  }

  var popupMenuTitle: String {
    let isCountingDown = timeline.countdown.isCountingDown(at: currentTick)
    let isWorkTime = report.currentPeriod.isWorkPeriod
    let isAtStartOfPeriod = report.currentPeriod.firstTick == report.tick

    switch (isCountingDown, isWorkTime, isAtStartOfPeriod) {
    case (true, true, true): return "Next break at \(nextPeriodETA.formatted(date: .omitted, time: .shortened))"
    case (true, true, false): return "Next break at \(nextPeriodETA.formatted(date: .omitted, time: .shortened))"
    case (true, false, true): return "Next work period at \(nextPeriodETA.formatted(date: .omitted, time: .shortened))"
    case (true, false, false): return "Next work period at \(nextPeriodETA.formatted(date: .omitted, time: .shortened))"
    case (false, true, true): return "Ready to start work?"
    case (false, true, false): return "Work interrupted at \(interruptionTime.formatted(date: .omitted, time: .shortened))"
    case (false, false, true): return "Ready for a break?"
    case (false, false, false): return "Break paused at \(interruptionTime.formatted(date: .omitted, time: .shortened))"
    }
  }

  var popupMenuTitleColor: UIColor {
    timeline.countdown.isCountingDown(at: currentTick)
      ? .label
      : .systemRed
  }

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

  var ringsData: RingsData {
    let trackColor: UIColor = timeline.countdown.isCountingDown(at: currentTick) ? .systemGray4 : .systemGray5

    let periodColor: UIColor
    let sessionColor: UIColor
    let targetColor: UIColor

    if timeline.countdown.isCountingDown(at: currentTick) {
      periodColor = report.currentPeriod.isWorkPeriod ? .systemRed : .systemOrange
      sessionColor = .green
      targetColor = .yellow
    } else {
      periodColor = .systemGray2
      sessionColor = .systemGray2
      targetColor = .systemGray2
    }

    return .init(period: .init(color: periodColor,
                               trackColor: trackColor,
                               label: .init(title: report.periodUpper,
                                            value: report.periodHeadline,
                                            subtitle: report.periodLower,
                                            caption: report.periodFooter),
                               value: report.periodProgress),

                 session: .init(color: sessionColor,
                                trackColor: trackColor,
                                label: .init(title: report.sessionUpper(Date()),
                                             value: report.sessionHeadline,
                                             subtitle: report.sessionLower,
                                             caption: report.sessionFooter),
                                value: report.sessionProgress),

                 target: .init(color: targetColor,
                               trackColor: trackColor,
                               label: .init(title: report.targetUpper,
                                            value: report.targetHeadline,
                                            subtitle: report.targetLower,
                                            caption: report.targetFooter),
                               value: report.targetProgress))
  }

  var ringsViewOnlyPortrait: RingsViewState {
    .init(content: ringsData,
          layout: preferredRingsLayoutInSingleColumnMode.portrait,
          prominentRing: prominentlyDisplayedRing)
  }

  var ringsViewOnlyLandscape: RingsViewState {
    .init(content: ringsData,
          layout: preferredRingsLayoutInSingleColumnMode.landscape,
          prominentRing: prominentlyDisplayedRing)
  }

  var ringsViewDataModeCompact: RingsViewState {
    .init(content: ringsData,
          layout: .init(acentricAxis: .alongLongestDimension,
                        concentricity: 0.0, scaleFactorWhenFullyAcentric: 1.0,
                        scaleFactorWhenFullyConcentric: 1.0),
          prominentRing: prominentlyDisplayedRing)
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
  case timeline(TimelineAction)
  case timer(TimerAction)
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
      .sink {
        let effect = appReducer(state: &self.state, action: $0)
        switch effect.f {
        case let .fireAndForget(f): f()
        case let .action(f): store.receiveAction = f()
        }
      }
      .store(in: &cancellables)
  }
}

enum TimerAction {
  case ticked
}

var cancellables: Set<AnyCancellable> = []

private func appReducer(state: inout AppViewState, action: AppViewAction) -> Effect {
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
      state.timeline.toggleCountdown(at: Date.init)

      return .fireAndForget {
        if cancellables.isEmpty {
          Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .map { _ in AppViewAction.timer(.ticked) }
            .assign(to: \.receiveAction, on: store)
            .store(in: &cancellables)
        } else {
          cancellables.removeAll()
        }
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

  case .timer:
    state.currentTick = state.timeline.countdown.tick(at: Date())

  case .timeline(.pause):
    state.timeline.pauseCountdown(at: Date.init)

    return .fireAndForget {
      cancellables.removeAll()
    }

  case .timeline(.restartCurrentPeriod):
    state.timeline.moveCountdownToStartOfCurrentPeriod(at: Date.init)
    state.currentTick = state.timeline.countdown.tick(at: Date())

    return .fireAndForget {
      cancellables.removeAll()

      Timer.publish(every: 1, on: .main, in: .default)
        .autoconnect()
        .map { _ in AppViewAction.timer(.ticked) }
        .assign(to: \.receiveAction, on: store)
        .store(in: &cancellables)
    }

  case .timeline(.resetTimelineToTickZero):
    state.timeline.resetCountdownToTickZero(date: Date.init)
    state.currentTick = state.timeline.countdown.tick(at: Date())

    return .fireAndForget {
      cancellables.removeAll()
    }

  case .timeline(.resume):
    state.timeline.resumeCountdown(from: Date.init)

    return .fireAndForget {
      cancellables.removeAll()

      Timer.publish(every: 1, on: .main, in: .default)
        .autoconnect()
        .map { _ in AppViewAction.timer(.ticked) }
        .assign(to: \.receiveAction, on: store)
        .store(in: &cancellables)
    }

  case .timeline(.skipCurrentPeriod):
    state.timeline.moveCountdownToStartOfNextPeriod(at: Date.init)
    state.currentTick = state.timeline.countdown.tick(at: Date())

    return .fireAndForget {
      cancellables.removeAll()

      Timer.publish(every: 1, on: .main, in: .default)
        .autoconnect()
        .map { _ in AppViewAction.timer(.ticked) }
        .assign(to: \.receiveAction, on: store)
        .store(in: &cancellables)
    }

  case .timeline(.toggle):
    state.timeline.toggleCountdown(at: Date.init)

    return .fireAndForget {
      if cancellables.isEmpty {
        Timer.publish(every: 1, on: .main, in: .default)
          .autoconnect()
          .map { _ in AppViewAction.timer(.ticked) }
          .assign(to: \.receiveAction, on: store)
          .store(in: &cancellables)
      } else {
        cancellables.removeAll()
      }
    }

  case .timeline(.changedTimeline):
    break
  }

  return .none
}

public class AppViewController: UIViewController {
  var cancellables: Set<AnyCancellable> = []

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
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
          let filteredSettings = store.settings.filter { $0 != nil }
            .map { $0! }
            .eraseToAnyPublisher()

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

    Publishers.Zip(store.$state.map(\.popupMenuTitle), store.$state.map(\.popupMenuTitleColor))
      .assign(to: \.title, on: bottomMenuPopup)
      .store(in: &cancellables)

    store.$state.map(\.popupMenuItems)
      .removeDuplicates { $0.map(\.title) == $1.map(\.title) }
      .assign(to: \.menuItems, on: bottomMenuPopup)
      .store(in: &cancellables)

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

  override public func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    // Nudge the store to force some output so the view gets a chance to re-render it's layout if needed
    // after a view bounds or traits change. This helps us avoid sending view state back into the store
    // forcing the view to interpret the best layout for it's orientation and size and not the store.
    store.receiveAction = .tabBarItemTapped(store.state.selectedDataTab)
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
      .map { .ringsView($0, whilePortrait: self.view.isPortrait) }
      .assign(to: &store.$receiveAction)

    return rings
  }()

  private lazy var topAppToolbar: AppToolbar = {
    AppToolbar(frame: .zero)
  }()

  private lazy var bottomMenuPopup: RingsPopupMenuView = {
    RingsPopupMenuView()
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

  private var demoMenu2: UIMenu {
    var menuItems: [UIAction] {
      [
        .startWorkPeriod,
        .skipToNextBreak,
      ]
      .reversed()
    }

    return UIMenu(children: menuItems)
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
      activityLog.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
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
      activityLog.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

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
      activityLog.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      activityLog.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

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
  public func tabBar(_: UITabBar, didSelect item: UITabBarItem) {
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.resume)
      }
    }
  }

  static var startWorkPeriod: UIAction {
    UIAction(title: "Start Work Period",
             image: UIImage(systemName: "arrow.right"),
             discoverabilityTitle: "Start Work Period") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.resume)
      }
    }
  }

  static var skipBreak: UIAction {
    UIAction(title: "Skip Break",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Skip Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.skipCurrentPeriod)
      }
    }
  }

  static var skipToNextWorkPeriod: UIAction {
    UIAction(title: "Skip To Next Work Period",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Skip To Next Work period") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.skipCurrentPeriod)
      }
    }
  }

  static var skipToNextBreak: UIAction {
    UIAction(title: "Skip To Next Break",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Skip To Next Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.skipCurrentPeriod)
      }
    }
  }

  static var resumeBreak: UIAction {
    UIAction(title: "Resume Break",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Resume Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.resume)
      }
    }
  }

  static var resumeWorkPeriod: UIAction {
    UIAction(title: "Resume Work Period",
             image: UIImage(systemName: "arrow.right"),
             discoverabilityTitle: "Resume Work Period") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.resume)
      }
    }
  }

  static var pauseBreak: UIAction {
    UIAction(title: "Pause Break",
             image: UIImage(systemName: "pause"),
             discoverabilityTitle: "Pause Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.pause)
      }
    }
  }

  static var pauseWorkPeriod: UIAction {
    UIAction(title: "Pause Work Period",
             image: UIImage(systemName: "pause"),
             discoverabilityTitle: "Pause Work Period") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.pause)
      }
    }
  }

  static var restartWorkPeriod: UIAction {
    UIAction(title: "Restart Work Period",
             image: UIImage(systemName: "arrow.left.to.line"),
             discoverabilityTitle: "Restart Work Period") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.restartCurrentPeriod)
      }
    }
  }

  static var restartBreak: UIAction {
    UIAction(title: "Restart Break",
             image: UIImage(systemName: "arrow.left.to.line"),
             discoverabilityTitle: "Restart Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        store.receiveAction = .timeline(.restartCurrentPeriod)
      }
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
      logEntry.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20)
      logEntry.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: 20)
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

struct Effect {
  enum EffectType {
    case action(() -> AppViewAction)
    case fireAndForget(() -> Void)
  }

  var f: EffectType

  static func fireAndForget(_ f: @escaping () -> Void) -> Effect {
    Effect(f: .fireAndForget(f))
  }

  static func send(_ f: @escaping () -> AppViewAction) -> Effect {
    Effect(f: .action(f))
  }

  static var none: Effect {
    Effect(f: .fireAndForget {})
  }
}

public struct RingsContent: Equatable {
  public struct RingContent: Equatable {
    let ringTitle: String
    let ringSubTitle: String
    let progress: Double
    let progressDescription: String
    let descriptionCaption: String
    let progressIndicatorColor: UIColor
    var trackColor: UIColor
    let estimatedTimeToCompleteDescription: String

    public init(ringTitle: String, ringSubTitle: String, progress: Double, progressDescription: String, descriptionCaption: String, progressIndicatorColor: UIColor, trackColor: UIColor, estimatedTimeToCompleteDescription: String) {
      self.ringTitle = ringTitle
      self.ringSubTitle = ringSubTitle
      self.progress = progress
      self.progressDescription = progressDescription
      self.descriptionCaption = descriptionCaption
      self.progressIndicatorColor = progressIndicatorColor
      self.trackColor = trackColor
      self.estimatedTimeToCompleteDescription = estimatedTimeToCompleteDescription
    }
  }

  let outer: RingContent
  let center: RingContent
  let inner: RingContent

  public init(outer: RingContent, center: RingContent, inner: RingContent) {
    self.outer = outer
    self.center = center
    self.inner = inner
  }
}

// public extension Report {
//  var ringsContent: RingsContent {
//    .init(
//      outer: .init(
//        ringTitle: periodUpper.0,
//        ringSubTitle: periodUpper.1,
//        progress: periodProgress,
//        progressDescription: periodHeadline,
//        descriptionCaption: periodLower,
//        progressIndicatorColor: currentPeriod.isWorkPeriod
//          ? .red
//          : .orange,
//        trackColor: .purple,
//        estimatedTimeToCompleteDescription: periodFooter
//      ),
//
//      center: .init(
//        ringTitle: sessionUpper(Date()).0,
//        ringSubTitle: sessionUpper(Date()).1,
//        progress: sessionProgress,
//        progressDescription: sessionHeadline,
//        descriptionCaption: sessionLower,
//        progressIndicatorColor: .green,
//        trackColor: .gray,
//        estimatedTimeToCompleteDescription: sessionFooter
//      ),
//
//      inner: .init(
//        ringTitle: targetUpper.0,
//        ringSubTitle: targetUpper.1,
//        progress: targetProgress,
//        progressDescription: targetHeadline,
//        descriptionCaption: targetLower,
//        progressIndicatorColor: .yellow,
//        trackColor: .gray,
//        estimatedTimeToCompleteDescription: targetFooter
//      )
//    )
//  }
// }

extension AppViewState {
  var nextPeriodETA: Date {
    guard let nextPeriod = report.nextPeriod else { return .distantFuture }

    return timeline.countdown.time(at: nextPeriod.tickRange.lowerBound)
  }

  var interruptionTime: Date {
    timeline.countdown.time(at: currentTick)
  }
}

public enum TimelineAction: Int, Equatable, Codable {
  case pause
  case restartCurrentPeriod
  case resetTimelineToTickZero
  case resume
  case skipCurrentPeriod
  case toggle
  case changedTimeline
}
