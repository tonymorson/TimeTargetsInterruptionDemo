import Combine
import ComposableArchitecture
import InterruptionPicker
import Notifications
import PromptFeature
import RingsView
import SettingsEditor
import SwiftUIKit
import Ticks
import Timeline
import TimelineReports
import UIKit
import UserNotifications

private struct RingsLayoutPair: Equatable {
  public var landscape: ConcentricityState
  public var portrait: ConcentricityState

  init(landscape: ConcentricityState, portrait: ConcentricityState) {
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

enum NavigationPath: Equatable {
  case interruptionSheet(InterruptionPickerState, Date)
  case settingsModal
}

public enum NavigationTabIdentifier: Codable {
  case today, tasks, charts
}

private struct AppState: Equatable {
  var appearance: Appearance
  var neverSleep: Bool
  var columnDisplayMode: DisplayMode
  var notificationSettings: NotificationsSettingsState
  var route: NavigationPath?
  var preferredRingsLayoutInSingleColumnMode: RingsLayoutPair
  var preferredRingsLayoutInDoubleColumnModeMode: ConcentricityState
  var prominentlyDisplayedRing: RingIdentifier
  var selectedDataTab: NavigationTabIdentifier
  var userActivities: UserActivitesState
  var pausedToInterruptionTimeout: Double = 5
  var clarifiedInterruption: Interruption?

  init() {
    appearance = .dark
    neverSleep = true
    columnDisplayMode = .singleColumn
    notificationSettings = .init()
    preferredRingsLayoutInSingleColumnMode = .init()
    preferredRingsLayoutInDoubleColumnModeMode = .init(acentricAxis: .alwaysVertical,
                                                       concentricity: 1.0,
                                                       scaleFactorWhenFullyAcentric: 1.0,
                                                       scaleFactorWhenFullyConcentric: 1.0)
    prominentlyDisplayedRing = .period
    selectedDataTab = .today
    preferredRingsLayoutInSingleColumnMode = .init()
    userActivities = .init(history: [])
  }

  var settings: SettingsEditorState {
    set {
      pausedToInterruptionTimeout = newValue.interruptionTimeout

      if settings.periods != newValue.periods {
        let periods = newValue.periods
        var timeline = Timeline(countdown: timeline.countdown,
                                dailyTarget: periods.dailyTarget,
                                resetWorkOnStop: periods.resetWorkPeriodOnStop,
                                periods: WorkPattern(work: periods.workPeriodDuration,
                                                     shortBreak: periods.shortBreakDuration,
                                                     longBreak: periods.longBreakDuration,
                                                     repeating: periods.longBreakFrequency - 1),
                                stopOnBreak: periods.pauseBeforeStartingBreaks,
                                stopOnWork: periods.pauseBeforeStartingWorkPeriods)

        timeline.countdown.ticks = timeline.countdown.startTick ... timeline.nextStopTick(at: Date.init)
        userActivitesReducer(state: &userActivities, action: .changedTimeline(timeline))
      }

      notificationSettings = newValue.notifications
      neverSleep = newValue.neverSleep
      appearance = newValue.appearance
    }

    get {
      var settings = SettingsEditorState(appearance: appearance,
                                         neverSleep: neverSleep,
                                         notifications: notificationSettings,
                                         periods: .init(timeline: timeline))

      settings.interruptionTimeout = pausedToInterruptionTimeout

      return settings
    }
  }

  var timeline: Timeline {
    userActivities.latestTimeline
  }

  var report: Report {
    .init(workPattern: timeline.periods,
          dailyTarget: timeline.dailyTarget,
          tick: userActivities.currentTick)
  }

  var popupMenuItems: [UIMenuElement] {
    let isCountingDown = userActivities.isCountingDown
    let isWorkTime = report.currentPeriod.isWorkPeriod
    let isAtStartOfPeriod = report.currentPeriod.firstTick == report.tick

    let logInterruptionMenu = UIMenu(options: .displayInline,
                                     children: [UIMenu(title: "Clarify Interruption...",
                                                       image: UIImage(systemName: "pencil"),
                                                       children: [
                                                         Interruption.conversation.uiAction,
                                                         Interruption.email.uiAction,
                                                         Interruption.socialMedia.uiAction,
                                                         Interruption.daydreaming.uiAction,
                                                         Interruption.phone.uiAction,
                                                         Interruption.message.uiAction,

                                                         UIMenu(title: "More...", children: [
                                                           Interruption.tired.uiAction,
                                                           Interruption.finished.uiAction,
                                                           Interruption.lunch.uiAction,
                                                           Interruption.other.uiAction,
                                                           Interruption.restroom.uiAction,
                                                           Interruption.underTheWeather.uiAction,
                                                           Interruption.health.uiAction,
                                                           Interruption.meeting.uiAction,
                                                           Interruption.powerFailure.uiAction,
                                                         ].reversed()),

                                                       ].reversed())])

    //    if let _ = userActivities.history.last?.interruption {
    //      return [Interruption.conversation.uiAction,
    //              Interruption.daydreaming.uiAction,
    //              Interruption.email.uiAction,
    //              Interruption.message.uiAction,
    //              Interruption.phone.uiAction,
    //              Interruption.socialMedia.uiAction,
    //
    //              UIMenu(title: "More...", children: [
    //                Interruption.finished.uiAction,
    //                Interruption.health.uiAction,
    //                Interruption.lunch.uiAction,
    //                Interruption.meeting.uiAction,
    //                Interruption.tired.uiAction,
    //                Interruption.powerFailure.uiAction,
    //                Interruption.restroom.uiAction,
    //                Interruption.underTheWeather.uiAction,
    //                Interruption.other.uiAction,
    //              ].reversed())].reversed()
    //    }

    switch (isCountingDown, isWorkTime, isAtStartOfPeriod) {
    case (true, true, true):
      return [UIAction.pauseWorkPeriod, UIAction.skipToNextBreak]

    case (true, true, false):
      return [UIAction.pauseWorkPeriod, UIAction.skipToNextBreak, UIAction.restartWorkPeriod]

    case (true, false, true):
      return [UIAction.pauseBreak, UIAction.skipBreak]

    case (true, false, false):
      return [UIAction.pauseBreak, UIAction.skipBreak, UIAction.restartBreak]

    case (false, true, true):
      return [UIAction.startWorkPeriod, UIAction.skipToNextBreak]

    case (false, true, false):
      return [logInterruptionMenu, UIAction.resumeWorkPeriod, UIAction.skipToNextBreak, UIAction.restartWorkPeriod]

    case (false, false, true):
      return [UIAction.startBreak, UIAction.skipBreak]

    case (false, false, false):
      return [logInterruptionMenu, UIAction.resumeBreak, UIAction.skipToNextWorkPeriod, UIAction.restartBreak]
    }
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

  var ringsData: Data {
    let isCountingDown = userActivities.isCountingDown

    let trackColor: UIColor = isCountingDown
      ? .systemGray4
      : .systemGray5

    let periodColor: UIColor
    let sessionColor: UIColor
    let targetColor: UIColor

    if isCountingDown {
      periodColor = report.currentPeriod.isWorkPeriod ? .systemRed : .systemOrange
      sessionColor = .green
      targetColor = .yellow
    } else {
      periodColor = .systemGray4
      sessionColor = .systemGray4
      targetColor = .systemGray4
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

  var ringsViewDataModeRegular: RingsViewState {
    .init(content: ringsData,
          layout: preferredRingsLayoutInDoubleColumnModeMode,
          prominentRing: prominentlyDisplayedRing)
  }

  var ringsView: RingsViewState {
    get { ringsViewDataModeRegular }
    set {}
  }
}

public enum NavigationAction: Equatable, Codable {
  case settingsEditorDismissed
  case settingsEditorSummoned
  case interruptionPickerDismissed
}

public enum AppAction: Equatable, Codable {
  case interruptionTapped(Interruption)
  case navigation(NavigationAction)
  case ringsView(RingsViewAction, whilePortrait: Bool)
  case ringsVieww(RingsViewAction)
  case settingsEditor(SettingsEditorAction)
  case showDataButtonTapped
  case tabBarItemTapped(NavigationTabIdentifier)
  case timeline(TimelineAction)
  case timer(TimerAction)
}

// @MainActor private let store = AppStore()

// @MainActor
// private class AppStore {
//  @Published var state = AppState()
//  @Published var receiveAction: AppAction?
//
//  var ringsDisplayMode: AnyPublisher<DisplayMode, Never> {
//    $state
//      .map(\.columnDisplayMode)
//      .removeDuplicates()
//      .eraseToAnyPublisher()
//  }
//
//  var ringsFocus: AnyPublisher<RingIdentifier, Never> {
//    $state
//      .map(\.prominentlyDisplayedRing)
//      .removeDuplicates()
//      .eraseToAnyPublisher()
//  }
//
////  var settings: AnyPublisher<SettingsEditorState?, Never> {
////    $state
////      .map { state -> SettingsEditorState? in
////        if case let .settingsViewController(editorState) = state.route {
////          return editorState
////        }
////
////        return nil
////      }
////      .removeDuplicates()
////      .eraseToAnyPublisher()
////  }
//
//  private var cancellables: Set<AnyCancellable> = []
//
//  init() {
//    $receiveAction
//      .compactMap { $0 }
//      .sink {
//        let effect = appReducer(state: &self.state, action: $0)
//
//        switch effect.f {
//        case let .fireAndForget(f):
//          Task {
//            await f()
//          }
//
//        case let .action(f):
//          Task {
//            store.receiveAction = await f()
//          }
//        }
//      }
//      .store(in: &cancellables)
//  }
// }

public enum TimerAction: Codable {
  case ticked
}

var cancellables: Set<AnyCancellable> = []

private let appReducer = Reducer.combine(
  Reducer<AppState, AppAction, Void> { state, action, _ in
    switch action {
    case .ringsView(let action, let whilePortrait):
      switch action {
      case .acentricRingsPinched(scaleFactor: let scaleFactor):
        switch state.columnDisplayMode {
        case .singleColumn:
          if whilePortrait {
            state.preferredRingsLayoutInSingleColumnMode.portrait.scaleFactorWhenFullyAcentric = scaleFactor
          } else {
            state.preferredRingsLayoutInSingleColumnMode.landscape.scaleFactorWhenFullyAcentric = scaleFactor
          }
        case .doubleColumn:
          state.preferredRingsLayoutInDoubleColumnModeMode.scaleFactorWhenFullyAcentric = scaleFactor
        }

      case .concentricRingsPinched(scaleFactor: let scaleFactor):
        switch state.columnDisplayMode {
        case .singleColumn:
          if whilePortrait {
            state.preferredRingsLayoutInSingleColumnMode.portrait.scaleFactorWhenFullyConcentric = scaleFactor
          } else {
            state.preferredRingsLayoutInSingleColumnMode.landscape.scaleFactorWhenFullyConcentric = scaleFactor
          }
        case .doubleColumn:
          state.preferredRingsLayoutInDoubleColumnModeMode.scaleFactorWhenFullyConcentric = scaleFactor
        }

      case .concentricRingsTappedInColoredBandsArea:
        switch state.prominentlyDisplayedRing {
        case .period: state.prominentlyDisplayedRing = .session
        case .session: state.prominentlyDisplayedRing = .target
        case .target: state.prominentlyDisplayedRing = .period
        }

      case .ringConcentricityDragged(concentricity: let concentricity):
        switch state.columnDisplayMode {
        case .singleColumn:
          if whilePortrait {
            state.preferredRingsLayoutInSingleColumnMode.portrait.concentricity = concentricity
          } else {
            state.preferredRingsLayoutInSingleColumnMode.landscape.concentricity = concentricity
          }
        case .doubleColumn:
          state.preferredRingsLayoutInDoubleColumnModeMode.concentricity = concentricity
        }

      case .ringsViewTapped(.some):

        cancellablePropertyAnimator?.stopAnimation(true)

        var isCountingDown = state.userActivities.isCountingDown

        userActivitesReducer(state: &state.userActivities, action: isCountingDown ? .pause : .resume)

        isCountingDown = state.userActivities.isCountingDown
        let isPaused = !isCountingDown
        state.clarifiedInterruption = nil

        if isPaused, state.pausedToInterruptionTimeout >= 0 {
          let scopeIdentifier = 0
          let title = "Significant interruption at \(state.interruptionTime.formatted(date: .omitted, time: .shortened))"
          let subtitle = "Provide reason for interruption?"
          state.route = .interruptionSheet(.init(scopeIdentifier: scopeIdentifier,
                                                 title: title,
                                                 subtitle: subtitle), Date().addingTimeInterval(state.pausedToInterruptionTimeout))
        } else {
          state.route = nil
        }

        let stateCpy = state

//      return .fireAndForget {
//        cancellables.removeAll()
//
//        if stateCpy.userActivities.isCountingDown {
//          Timer.publish(every: 1, on: .main, in: .default)
//            .autoconnect()
//            .map { _ in AppAction.timer(.ticked) }
//            .assign(to: \.receiveAction, on: store)
//            .store(in: &cancellables)
//        } else {
//          Timer.publish(every: 1, on: .main, in: .default)
//            .autoconnect()
//            .map { _ in AppAction.timer(.ticked) }
//            .assign(to: \.receiveAction, on: store)
//            .store(in: &cancellables)
//        }
//      }

      case .ringsViewTapped(.none):
        break
      }

    case .ringsVieww:
      break

    case .settingsEditor(let action):
      settingsEditorReducer(state: &state.settings, action: action)
      state.route = .settingsModal

    case .showDataButtonTapped:
      state.columnDisplayMode.toggle()

    case .navigation(.settingsEditorSummoned):
      state.route = .settingsModal

    case .navigation(.settingsEditorDismissed):
      state.route = nil

    case .tabBarItemTapped(let tab):
      state.selectedDataTab = tab

    case .timer:
      state.userActivities.currentTick = state.timeline.countdown.tick(at: Date())

    case .timeline(.pause):
      userActivitesReducer(state: &state.userActivities, action: .pause)

      return .fireAndForget {
        cancellables.removeAll()
      }

    case .timeline(.restartCurrentPeriod):
      userActivitesReducer(state: &state.userActivities, action: .restartCurrentPeriod)

    case .timeline(.resetTimelineToTickZero):
      userActivitesReducer(state: &state.userActivities, action: .resetTimelineToTickZero)

      return .fireAndForget {
        cancellables.removeAll()
      }

    case .timeline(.resume):
      userActivitesReducer(state: &state.userActivities, action: .resume)

//    return .fireAndForget {
//      cancellables.removeAll()
//
//      Timer.publish(every: 1, on: .main, in: .default)
//        .autoconnect()
//        .map { _ in AppAction.timer(.ticked) }
//        .assign(to: \.receiveAction, on: store)
//        .store(in: &cancellables)
//    }

    case .timeline(.skipCurrentPeriod):
      userActivitesReducer(state: &state.userActivities, action: .skipCurrentPeriod)

//    return .fireAndForget {
//      cancellables.removeAll()
//
//      Timer.publish(every: 1, on: .main, in: .default)
//        .autoconnect()
//        .map { _ in AppAction.timer(.ticked) }
//        .assign(to: \.receiveAction, on: store)
//        .store(in: &cancellables)
//    }

    case .timeline(.changedTimeline):
      fatalError()

    case .interruptionTapped(let interruption):
      state.clarifiedInterruption = interruption
      state.route = nil

    case .navigation(.interruptionPickerDismissed):
      state.route = nil
    }

    return .none
  },

  ringsViewReducer.pullback(state: \.ringsView, action: /AppAction.ringsVieww, environment: {})
)

private func appReducer(state: inout AppState, action: AppAction) -> Effect {
  switch action {
  case .ringsView(let action, let whilePortrait):
    switch action {
    case .acentricRingsPinched(scaleFactor: let scaleFactor):
      switch state.columnDisplayMode {
      case .singleColumn:
        if whilePortrait {
          state.preferredRingsLayoutInSingleColumnMode.portrait.scaleFactorWhenFullyAcentric = scaleFactor
        } else {
          state.preferredRingsLayoutInSingleColumnMode.landscape.scaleFactorWhenFullyAcentric = scaleFactor
        }
      case .doubleColumn:
        state.preferredRingsLayoutInDoubleColumnModeMode.scaleFactorWhenFullyAcentric = scaleFactor
      }

    case .concentricRingsPinched(scaleFactor: let scaleFactor):
      switch state.columnDisplayMode {
      case .singleColumn:
        if whilePortrait {
          state.preferredRingsLayoutInSingleColumnMode.portrait.scaleFactorWhenFullyConcentric = scaleFactor
        } else {
          state.preferredRingsLayoutInSingleColumnMode.landscape.scaleFactorWhenFullyConcentric = scaleFactor
        }
      case .doubleColumn:
        state.preferredRingsLayoutInDoubleColumnModeMode.scaleFactorWhenFullyConcentric = scaleFactor
      }

    case .concentricRingsTappedInColoredBandsArea:
      switch state.prominentlyDisplayedRing {
      case .period: state.prominentlyDisplayedRing = .session
      case .session: state.prominentlyDisplayedRing = .target
      case .target: state.prominentlyDisplayedRing = .period
      }

    case .ringConcentricityDragged(concentricity: let concentricity):
      switch state.columnDisplayMode {
      case .singleColumn:
        if whilePortrait {
          state.preferredRingsLayoutInSingleColumnMode.portrait.concentricity = concentricity
        } else {
          state.preferredRingsLayoutInSingleColumnMode.landscape.concentricity = concentricity
        }
      case .doubleColumn:
        state.preferredRingsLayoutInDoubleColumnModeMode.concentricity = concentricity
      }

    case .ringsViewTapped(.some):

      cancellablePropertyAnimator?.stopAnimation(true)

      var isCountingDown = state.userActivities.isCountingDown

      userActivitesReducer(state: &state.userActivities, action: isCountingDown ? .pause : .resume)

      isCountingDown = state.userActivities.isCountingDown
      let isPaused = !isCountingDown
      state.clarifiedInterruption = nil

      if isPaused, state.pausedToInterruptionTimeout >= 0 {
        let scopeIdentifier = 0
        let title = "Significant interruption at \(state.interruptionTime.formatted(date: .omitted, time: .shortened))"
        let subtitle = "Provide reason for interruption?"
        state.route = .interruptionSheet(.init(scopeIdentifier: scopeIdentifier,
                                               title: title,
                                               subtitle: subtitle), Date().addingTimeInterval(state.pausedToInterruptionTimeout))
      } else {
        state.route = nil
      }

      let stateCpy = state

//      return .fireAndForget {
//        cancellables.removeAll()
//
//        if stateCpy.userActivities.isCountingDown {
//          Timer.publish(every: 1, on: .main, in: .default)
//            .autoconnect()
//            .map { _ in AppAction.timer(.ticked) }
//            .assign(to: \.receiveAction, on: store)
//            .store(in: &cancellables)
//        } else {
//          Timer.publish(every: 1, on: .main, in: .default)
//            .autoconnect()
//            .map { _ in AppAction.timer(.ticked) }
//            .assign(to: \.receiveAction, on: store)
//            .store(in: &cancellables)
//        }
//      }

    case .ringsViewTapped(.none):
      break
    }

  case .ringsVieww:
    break

  case .settingsEditor(let action):
    settingsEditorReducer(state: &state.settings, action: action)
    state.route = .settingsModal

  case .showDataButtonTapped:
    state.columnDisplayMode.toggle()

  case .navigation(.settingsEditorSummoned):
    state.route = .settingsModal

  case .navigation(.settingsEditorDismissed):
    state.route = nil

  case .tabBarItemTapped(let tab):
    state.selectedDataTab = tab

  case .timer:
    state.userActivities.currentTick = state.timeline.countdown.tick(at: Date())

  case .timeline(.pause):
    userActivitesReducer(state: &state.userActivities, action: .pause)

    return .fireAndForget {
      cancellables.removeAll()
    }

  case .timeline(.restartCurrentPeriod):
    userActivitesReducer(state: &state.userActivities, action: .restartCurrentPeriod)

  case .timeline(.resetTimelineToTickZero):
    userActivitesReducer(state: &state.userActivities, action: .resetTimelineToTickZero)

    return .fireAndForget {
      cancellables.removeAll()
    }

  case .timeline(.resume):
    userActivitesReducer(state: &state.userActivities, action: .resume)

//    return .fireAndForget {
//      cancellables.removeAll()
//
//      Timer.publish(every: 1, on: .main, in: .default)
//        .autoconnect()
//        .map { _ in AppAction.timer(.ticked) }
//        .assign(to: \.receiveAction, on: store)
//        .store(in: &cancellables)
//    }

  case .timeline(.skipCurrentPeriod):
    userActivitesReducer(state: &state.userActivities, action: .skipCurrentPeriod)

//    return .fireAndForget {
//      cancellables.removeAll()
//
//      Timer.publish(every: 1, on: .main, in: .default)
//        .autoconnect()
//        .map { _ in AppAction.timer(.ticked) }
//        .assign(to: \.receiveAction, on: store)
//        .store(in: &cancellables)
//    }

  case .timeline(.changedTimeline):
    fatalError()

  case .interruptionTapped(let interruption):
    state.clarifiedInterruption = interruption
    state.route = nil

  case .navigation(.interruptionPickerDismissed):
    state.route = nil
  }

  return .none
}

var cancellablePropertyAnimator: UIViewPropertyAnimator?

@MainActor
public class AppViewController: UIViewController {
  fileprivate let sstore = Store<AppState, AppAction>(initialState: .init(), reducer: appReducer, environment: ())
  fileprivate var viewStore: ViewStore<AppState, AppAction>!

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

    viewStore = ViewStore(sstore)

    overrideUserInterfaceStyle = .dark
    view.backgroundColor = .systemBackground

    view.tintColor = .systemRed

    // Configure top toolbar

    view.host(topAppToolbar) { toolbar, host in
      toolbar.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor, constant: 10)
      toolbar.leadingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.leadingAnchor)
      toolbar.trailingAnchor.constraint(equalTo: host.safeAreaLayoutGuide.trailingAnchor)
    }

    // Add bottom menu pop view below the rings view

    view.host(bottomMenuPopup)

    // Configure tab bar

    view.host(tabBar)

    // Configure rings view

    view.host(ringsView) { v, p in
      v.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor)
      v.bottomAnchor.constraint(equalTo: p.safeAreaLayoutGuide.bottomAnchor)
      v.leadingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.leadingAnchor)
      v.trailingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.trailingAnchor)
    }

    // Configure settings editor

    ////    store.settings
    ////      .filter { $0 != nil }
    ////      .sink { _ in
    ////        if self.presentedViewController == nil {
    ////          let filteredSettings = store.settings.filter { $0 != nil }
    ////            .map { $0! }
    ////            .eraseToAnyPublisher()
    ////
    ////          let editor = SettingsEditor(state: filteredSettings)
    ////          editor.onDismiss = { store.receiveAction = .navigation(.settingsEditorDismissed) }
    ////
    ////          self.present(editor, animated: true)
    ////
    ////          (editor.viewControllers.first)?
    ////            .navigationBarItems(leading: { BarButtonItem(.cancel) { store.receiveAction = .navigation(.settingsEditorDismissed) } })
    ////            .navigationBarItems(trailing: { BarButtonItem(.done) { store.receiveAction = .navigation(.settingsEditorDismissed) } })
    ////
    ////          editor.sentActions
    ////            .map(AppAction.settingsEditor)
    ////            .assign(to: &store.$receiveAction)
    ////        }
    ////      }
    ////      .store(in: &cancellables)
//
//    store.$state
//      .map(\.route)
//      .removeDuplicates()
//      .sink { route in
//
    ////        if self.presentedViewController is SettingsEditor {
    ////          self.dismiss(animated: true)
    ////        }
//
//      switch route {
//
//      case .none:
//        if self.presentedViewController is SettingsEditor {
//                  self.dismiss(animated: true)
//                }
//
//      case .some(.settingsModal):
//                if self.presentedViewController == nil {
//                  let filteredSettings = store.$state.map(\.settings)
//                    .eraseToAnyPublisher()
//
//                  let editor = SettingsEditor(state: filteredSettings)
    ////                  editor.onDismiss = { store.receiveAction = .navigation(.settingsEditorDismissed) }
//                  editor.onDismiss = { self.viewStore.send(.navigation(.settingsEditorDismissed)) }
//
//                  self.present(editor, animated: true)
//
//                  (editor.viewControllers.first)?
//                    .navigationBarItems(leading: { BarButtonItem(.cancel) { store.receiveAction = .navigation(.settingsEditorDismissed) } })
//                    .navigationBarItems(trailing: { BarButtonItem(.done) { store.receiveAction = .navigation(.settingsEditorDismissed) } })
//
//                  editor.sentActions
//                    .map(AppAction.settingsEditor)
//                    .assign(to: &store.$receiveAction)
//                }
//
//      case .some(.interruptionSheet(let state, let date)):
//        if self.presentedViewController is SettingsEditor {
//                  self.dismiss(animated: true)
//                }
//      }
//    }
//      .store(in: &cancellables)
//
    ////    store.settings
    ////      .filter { $0 == nil }
    ////      .sink { _ in
    ////        if self.presentedViewController is SettingsEditor {
    ////          self.dismiss(animated: true)
    ////        }
    ////      }
    ////      .store(in: &cancellables)
//
//    // Configure segmented control
//
//    store.$state
//      .map(\.columnDisplayMode)
//      .map { $0 == .doubleColumn &&
//        !(self.view.isPortrait &&
//          self.traitCollection.horizontalSizeClass == .compact &&
//          self.traitCollection.verticalSizeClass == .regular)
//      }
//      .removeDuplicates()
//      .sink { shouldShow in
//        self.topAppToolbar.isShowingExtraButton(isShowing: shouldShow)
//      }
//      .store(in: &cancellables)
//
//    view.host(activityLogHeading)
//    view.host(activityLog)
//
//    //    store.$state
//    //      .map(\.standardMessage)
//    //      .removeDuplicates()
//    //      .sink { value in
//    //        // https://stackoverflow.com/questions/3073520/animate-text-change-in-uilabel
//    //        let animation = CATransition()
//    //
//    //        let interval: CFTimeInterval = value.message.isEmpty
//    //        ? 1.0
//    //        : 0.15
//    //
//    //        animation.duration = interval
//    //        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//    //        self.bottomMenuPopup.layer.add(animation, forKey: nil)
//    //        self.bottomMenuPopup.title = value.message.isEmpty
//    //        ? (" ", UIColor.systemRed)
//    //        : (value.message, UIColor.systemRed)
//    //
//    //        self.bottomMenuPopup.subtitle = value.subMessage.isEmpty
//    //        ? (" ", UIColor.systemRed)
//    //        : (value.subMessage, UIColor.label)
//    //      }
//    //      .store(in: &cancellables)
//
//    //    Publishers.Zip(store.$state.map(\.popupMenuTitle), store.$state.map(\.popupMenuTitleColor))
//    //      .removeDuplicates { $0.0 == $1.0 }
//    //      .sink { value in
//    //        // https://stackoverflow.com/questions/3073520/animate-text-change-in-uilabel
//    //        let animation = CATransition()
//    //
//    //        let interval: CFTimeInterval = value.0.isEmpty
//    //        ? 1.0
//    //        : 0.15
//    //
//    //        animation.duration = interval
//    //        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//    //        self.bottomMenuPopup.layer.add(animation, forKey: nil)
//    //        self.bottomMenuPopup.title = value.0.isEmpty ? (" ", value.1) : value
//    //      }
//    //      .store(in: &cancellables)
//
//    //    Publishers.Zip(store.$state.map(\.popupMenuSubtitle), store.$state.map { _ in .label })
//    //      .removeDuplicates { $0.0 == $1.0 }
//    //      .map { $0.0.isEmpty ? (" ", $0.1) : $0 }
//    //      .assign(to: \.subtitle, on: bottomMenuPopup)
//    //      .store(in: &cancellables)
//
//    //    Publishers.Zip(store.$state.map(\.popupMenuSubtitle), store.$state.map { _ in UIColor.label })
//    //      .removeDuplicates { $0.0 == $1.0 }
//    //      .map { $0.0.isEmpty ? (" ", $0.1) : $0 }
//    //      .sink { value in
//    //      // https://stackoverflow.com/questions/3073520/animate-text-change-in-uilabel
//    //      let animation = CATransition()
//    //
//    //      let interval: CFTimeInterval = value.0.isEmpty
//    //      ? 1.0
//    //      : 0.15
//    //
//    //      animation.duration = interval
//    //      animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//    //      self.bottomMenuPopup.layer.add(animation, forKey: nil)
//    //        self.bottomMenuPopup.subtitle = self.bottomMenuPopup.subtitle.0.isEmpty ? (" ", value.1) : value
//    //    }      .store(in: &cancellables)
//
//    store.$state.map(\.popupMenuItems)
//      .removeDuplicates { $0.map(\.title) == $1.map(\.title) }
//      .map { $0.reversed() }
//      .assign(to: \.menuItems, on: bottomMenuPopup)
//      .store(in: &cancellables)
//
//    store.$state
//      .map(\.columnDisplayMode)
//      .map { $0 == .doubleColumn && !(self.view.isPortrait && self.traitCollection.horizontalSizeClass == .compact && self.traitCollection.verticalSizeClass == .regular) }
//      .removeDuplicates()
//      .sink { shouldShow in
//        self.topAppToolbar.isShowingExtraButton(isShowing: shouldShow)
//      }
//      .store(in: &cancellables)
//
//    store.$state
//      .map { state -> CGFloat in
//
    ////        self.view.backgroundColor = state.report.currentPeriod.isWorkPeriod
    ////          ? .systemRed.lighter!.lighter!
    ////        : .systemOrange.lighter!.lighter!.slightyLighter!
    ////
    ////        if state.userActivities.isCountingDown == false {
    ////          self.view.backgroundColor = .systemBackground
    ////        }
    ////
//        (state.columnDisplayMode == .doubleColumn) && self.view.isPortrait && self.traitCollection.horizontalSizeClass == .compact ? 1.0 : 0.0
//      }
//      .removeDuplicates()
//      .assign(to: \.alpha, on: tabBar)
//      .store(in: &cancellables)
//
//    store.$state
//      .removeDuplicates()
//      .sink { [weak self] in
//        guard let self = self else { return }
//        let isShowingData = $0.columnDisplayMode == .doubleColumn
//
//        self.noShowDataLayoutMode = self.traitCollection.horizontalSizeClass == .compact
//          ? self.singleColumnRingsOnly
//          : self.singleColumnRingsOnly
//
//        let x = $0.selectedDataTab == .today ? self.doubleColumnRingsLeft : self.doubleColumnRingsRight
//        self.showDataLayoutMode = self.traitCollection.horizontalSizeClass == .compact
//          ? self.view.isPortrait ? self.compactWidthLayout2 : x
//          : x
//
//        NSLayoutConstraint.deactivate(self.singleColumnRingsOnly)
//        NSLayoutConstraint.deactivate(self.compactWidthLayout)
//        NSLayoutConstraint.deactivate(self.compactWidthLayout2)
//        NSLayoutConstraint.deactivate(self.normalWidthLayout)
//        NSLayoutConstraint.deactivate(self.doubleColumnRingsLeft)
//        NSLayoutConstraint.deactivate(self.doubleColumnRingsRight)
//
//        if isShowingData {
//          NSLayoutConstraint.activate(self.showDataLayoutMode)
//        } else {
//          NSLayoutConstraint.activate(self.singleColumnRingsOnly)
//        }
//      }
//      .store(in: &cancellables)
//
//    store.menuPopupViewModel
//      .removeDuplicates()
//      .assign(to: \.viewModel, on: bottomMenuPopup)
//      .store(in: &cancellables)
//
//    store.resumeSoonProgressBarViewModel
//      .removeDuplicates()
//      .sink { [weak self] viewModel in
//        if viewModel != nil {
//          guard let strongSelf = self else { return }
//          let cancellableProgressBar = UIProgressView()
//          cancellableProgressBar.tag = 1_923_338
//          strongSelf.bottomMenuPopupProgressBar = cancellableProgressBar
//          cancellableProgressBar.isHidden = store.state.pausedToInterruptionTimeout < 0
//          cancellableProgressBar.progress = 0.01
//
//          if store.state.pausedToInterruptionTimeout >= 0 {
//            cancellableProgressBar.progress = 0.01
//            cancellableProgressBar.alpha = 0.75
//
//            cancellablePropertyAnimator = cancellableProgressBar.animator(duration: store.state.pausedToInterruptionTimeout) { _ in }
//
//            cancellablePropertyAnimator?.startAnimation()
//          }
//        } else {
//          self?.view.viewWithTag(1_923_338)?.removeFromSuperview()
//          cancellablePropertyAnimator?.stopAnimation(true)
//          cancellablePropertyAnimator = nil
//        }
//      }
//      .store(in: &cancellables)
//
//    // Triggered when global state changes its InterruptionPickerState.
//    store.$state
//      .map(\.route)
//      .map { route -> InterruptionPickerState? in
//        switch route {
//        case let .interruptionSheet(state, date):
//          if Date() > date {
//            return Optional(state)
//          } else {
//            return nil
//          }
//        default:
//          return nil
//        }
//      }
//      .removeDuplicates()
//      .sink { interruptionPickerState in
//
//        // If something is already being presented, tear it down.
//        // We may need to do this if a context menu is currently
//        // being shown for example.
//        if self.presentedViewController != nil {
//          self.dismiss(animated: true)
//        }
//
//        // Exit early if we are not presenting a new interruption picker.
//        if interruptionPickerState == nil {
//          return
//        }
//
//        // Otherwise, create a new interruption picker and prepare to present it as a modal half sheet.
//        let interruptionPicker = InterruptionPickerViewController(state: interruptionPickerState!)
//        interruptionPicker.modalPresentationStyle = .pageSheet
//        if let sheet = interruptionPicker.sheetPresentationController {
//          sheet.preferredCornerRadius = 20
//          sheet.prefersGrabberVisible = true
//          sheet.prefersScrollingExpandsWhenScrolledToEdge = false
//          sheet.detents = [.medium(), .large()]
//        }
//
//        // Show the picker on the screen and give the store a chance to update its state.
//        self.present(interruptionPicker, animated: true, completion: {
//          store.receiveAction = .timer(.ticked)
//        })
//
//        // Wait for the user to perform an action and then send it to the store.
//        Task {
//          for await action in interruptionPicker.actions {
//            switch action {
//            case .dismissed:
//              store.receiveAction = .navigation(.interruptionPickerDismissed)
//            case let .interruptionTapped(interruption):
//              store.receiveAction = .interruptionTapped(interruption)
//            }
//          }
//        }
//      }
//      .store(in: &cancellables)
//
//    store.$state
//      .map(\.appearance)
//      .removeDuplicates()
//      .receive(on: DispatchQueue.main)
//      .map { theme -> UIUserInterfaceStyle in
//        switch theme {
//        case .dark:
//          return .dark
//        case .light:
//          return .light
//        case .auto:
//          return .unspecified
//        }
//      }
//      .sink { theme in
//        UIView.animate(withDuration: 0.5) {
//          UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = theme
//          self.overrideUserInterfaceStyle = theme
//        }
//      }
//      .store(in: &cancellables)
//
//    store.$state
//      .map(\.shouldStayAwake)
//      .removeDuplicates()
//      .receive(on: DispatchQueue.main)
//      .sink { shouldStawyAwake in
//        UIApplication.shared.isIdleTimerDisabled = shouldStawyAwake
//      }
//      .store(in: &cancellables)
//
    ////    store.notifications
    ////      .removeDuplicates { $0.timeline == $1.timeline && $0.settings == $1.settings }
    ////      .sink { notificationSettings in
    ////        Task {
    ////          do {
    ////          let authorization = try await UNUserNotificationCenter.current()
    ////            .requestAuthorization(options: [.alert, .sound, .providesAppNotificationSettings])
    ////
    ////          if authorization == true {
    ////            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    ////
    ////            let factory = NotificationsFactory()
    ////            let notificationRequests = await factory.makeCountingDownNotifications(for: notificationSettings.timeline, at: notificationSettings.currentTick)
    ////
    ////            for notification in notificationRequests {
    ////              try await UNUserNotificationCenter.current().add(notification)
    ////            }
    ////
    //////            for notification in timeline.makeCountdownPausedSignificantlyNotifications() {
    //////              try await UNUserNotificationCenter.current().add(notification)
    //////            }
    ////
    //////            timeline.makeCountdownPausedSignificantlyNotifications()
    //////              .forEach { notificationRequest in
    //////                UNUserNotificationCenter.current().add(notificationRequest)
    //////              }
    ////
    ////          }
    ////          } catch {
    ////            print (error)
    ////          }
    ////        }
    ////      }
    ////      .store(in: &cancellables)
//
//    UNUserNotificationCenter.current().delegate = self
  }

  override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)

    coordinator.animate { _ in
      // Nudge the store to force some output so the view gets a chance to re-render it's layout if needed
      // after a view bounds or traits change. This helps us avoid sending view state back into the store
      // forcing the view to interpret the best layout for it's orientation and size and not the store.
//      store.receiveAction = .tabBarItemTapped(store.state.selectedDataTab)
      self.viewStore?.send(.tabBarItemTapped(self.viewStore.state.selectedDataTab))
    }
  }

  private lazy var ringsView: RingsView = {
    let storeRingsOutput = viewStore.publisher
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

    let rings = RingsView(state: .init())

//    storeRingsOutput
//      .assign(to: \.state, on: rings)
//      .store(in: &cancellables)
//
//    rings.$sentActions
//      .compactMap { $0 }
    ////      .map { .ringsView($0, whilePortrait: self.view.isPortrait) }
//      .sink { self.viewStore.send(.ringsView($0, whilePortrait: true))}
//      .store(in: &cancellables)
    ////      .assign(to: self.viewStore.send)

    return rings
  }()

  private lazy var topAppToolbar: AppToolbar = {
    AppToolbar(frame: .zero)
  }()

  private lazy var bottomMenuPopup: RingsPopupMenuView = {
    RingsPopupMenuView()
  }()

  private var bottomMenuPopupProgressBar: UIProgressView? {
    didSet {
      oldValue?.removeFromSuperview()
      cancellablePropertyAnimator?.stopAnimation(true)
      cancellablePropertyAnimator = nil

      if let bar = bottomMenuPopupProgressBar {
        bottomMenuPopup.host(bar) { bar, view in
          bar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 2)
          bar.centerXAnchor.constraint(equalTo: view.centerXAnchor)
          bar.widthAnchor.constraint(equalToConstant: 168)
          bar.heightAnchor.constraint(equalToConstant: 5)
        }
        bar.progressTintColor = .systemRed
        bar.trackTintColor = .systemFill
        bar.alpha = 0.0
        view.layoutIfNeeded()
      }
    }
  }

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

  private lazy var activityLog: ActivityLog = {
    ActivityLog(frame: .zero)
  }()

  private lazy var activityLogHeading: ActivityLogHeading = {
    ActivityLogHeading(frame: .zero,
//                       input: store.$state
                       input: Just(("", "")).eraseToAnyPublisher())
//                         .map(\.dataHeadlineContent)
//                         .compactMap { $0 }
//                         .eraseToAnyPublisher())
  }()

  var noShowDataLayoutMode: [NSLayoutConstraint] = []
  var showDataLayoutMode: [NSLayoutConstraint] = []

  lazy var singleColumnRingsOnly: [NSLayoutConstraint] = {
    [
      ringsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      ringsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      ringsView.topAnchor.constraint(equalTo: topAppToolbar.bottomAnchor),
      ringsView.bottomAnchor.constraint(equalTo: bottomMenuPopup.topAnchor),

      bottomMenuPopup.centerXAnchor.constraint(equalTo: ringsView.centerXAnchor),
      bottomMenuPopup.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
      bottomMenuPopup.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bottomMenuPopup.trailingAnchor.constraint(equalTo: view.trailingAnchor),

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
    case 0: viewStore.send(.tabBarItemTapped(.today))
    case 1: viewStore.send(.tabBarItemTapped(.tasks))
    case 2: viewStore.send(.tabBarItemTapped(.charts))
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
//        store.receiveAction = .timeline(.resume)
      }
    }
  }

  static var startWorkPeriod: UIAction {
    UIAction(title: "Start Work Period",
             image: UIImage(systemName: "arrow.right"),
             discoverabilityTitle: "Start Work Period") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
//        store.receiveAction = .timeline(.resume)
      }
    }
  }

  static var skipBreak: UIAction {
    UIAction(title: "Skip Break",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Skip Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
//        store.receiveAction = .timeline(.skipCurrentPeriod)
      }
    }
  }

  static var skipToNextWorkPeriod: UIAction {
    UIAction(title: "Skip To Next Work Period",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Skip To Next Work period") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
//        store.receiveAction = .timeline(.skipCurrentPeriod)
      }
    }
  }

  static var skipToNextBreak: UIAction {
    UIAction(title: "Skip To Next Break",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Skip To Next Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
//        store.receiveAction = .timeline(.skipCurrentPeriod)
      }
    }
  }

  static var resumeBreak: UIAction {
    UIAction(title: "Resume Break",
             image: UIImage(systemName: "arrow.right.to.line"),
             discoverabilityTitle: "Resume Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
//        store.receiveAction = .timeline(.resume)
      }
    }
  }

  static var resumeWorkPeriod: UIAction {
    UIAction(title: "Resume Work Period",
             image: UIImage(systemName: "arrow.right"),
             discoverabilityTitle: "Resume Work Period") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
//        store.receiveAction = .timeline(.resume)
      }
    }
  }

  static var pauseBreak: UIAction {
    UIAction(title: "Pause Break",
             image: UIImage(systemName: "pause"),
             discoverabilityTitle: "Pause Break") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
//        store.receiveAction = .timeline(.pause)
      }
    }
  }

  static var pauseWorkPeriod: UIAction {
    UIAction(title: "Pause Work Period",
             image: UIImage(systemName: "pause"),
             discoverabilityTitle: "Pause Work Period") { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
//        store.receiveAction = .timeline(.pause)
      }
    }
  }

  static var restartWorkPeriod: UIAction {
    UIAction(title: "Restart Work Period",
             image: UIImage(systemName: "arrow.left.to.line"),
             discoverabilityTitle: "Restart Work Period") { _ in
//      store.receiveAction = .timeline(.restartCurrentPeriod)
    }
  }

  static var restartBreak: UIAction {
    UIAction(title: "Restart Break",
             image: UIImage(systemName: "arrow.left.to.line"),
             discoverabilityTitle: "Restart Break") { _ in
//      store.receiveAction = .timeline(.restartCurrentPeriod)
    }
  }

  static var dismissSettingsEditor: UIAction {
    UIAction(title: "Cancel", discoverabilityTitle: "Cancel") { _ in
//      store.receiveAction = .navigation(.settingsEditorDismissed)
    }
  }

  static var showSettingsEditor: UIAction {
    UIAction(image: UIImage(systemName: "gear"), discoverabilityTitle: "Show Settings") { _ in
//      store.receiveAction = .navigation(.settingsEditorSummoned)
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
//        store.receiveAction = .showDataButtonTapped
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
//        store.receiveAction = .tabBarItemTapped(.charts)
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
//        store.receiveAction = .tabBarItemTapped(.tasks)
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
//        store.receiveAction = .tabBarItemTapped(.today)
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
  var cancellables = Set<AnyCancellable>()

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
    logEntry.text = "2:30 PM  Work paused to take phone call"
    logEntry.font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: nil).rounded()

    host(logEntry) { logEntry, parent in
      logEntry.leadingAnchor.constraint(equalTo: parent.leadingAnchor)
      logEntry.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20)
      logEntry.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: 20)
    }

//    store.$state
//      .map(\.userActivities.history)
//      .removeDuplicates()
//      .map { history -> String in
//        "\(history.count) user events so far... (Last event: \(history.last?.action.logName ?? "None"))"
//      }
//      .assign(to: \.text, on: logEntry)
//      .store(in: &cancellables)
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

    let subtitle = UILabel(frame: .zero)
    subtitle.text = "5 Events"
    subtitle.font = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: nil).rounded()
    subtitle.textColor = .systemRed
    subtitle.textAlignment = .left

    host(subtitle) { subtitle, _ in
      subtitle.leadingAnchor.constraint(equalTo: self.leadingAnchor)
      subtitle.topAnchor.constraint(equalTo: title.bottomAnchor)
      subtitle.trailingAnchor.constraint(equalTo: self.trailingAnchor)
      subtitle.bottomAnchor.constraint(equalTo: self.bottomAnchor)
    }

    input
      .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
      .sink { details in
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

// public struct RingsContent: Equatable {
//  public struct RingContent: Equatable {
//    let ringTitle: String
//    let ringSubTitle: String
//    let progress: Double
//    let progressDescription: String
//    let descriptionCaption: String
//    let progressIndicatorColor: UIColor
//    var trackColor: UIColor
//    let estimatedTimeToCompleteDescription: String
//
//    public init(ringTitle: String, ringSubTitle: String, progress: Double, progressDescription: String, descriptionCaption: String, progressIndicatorColor: UIColor, trackColor: UIColor, estimatedTimeToCompleteDescription: String) {
//      self.ringTitle = ringTitle
//      self.ringSubTitle = ringSubTitle
//      self.progress = progress
//      self.progressDescription = progressDescription
//      self.descriptionCaption = descriptionCaption
//      self.progressIndicatorColor = progressIndicatorColor
//      self.trackColor = trackColor
//      self.estimatedTimeToCompleteDescription = estimatedTimeToCompleteDescription
//    }
//  }
//
//  let outer: RingContent
//  let center: RingContent
//  let inner: RingContent
//
//  public init(outer: RingContent, center: RingContent, inner: RingContent) {
//    self.outer = outer
//    self.center = center
//    self.inner = inner
//  }
// }

extension AppState {
  var nextPeriodETA: Date {
    guard let nextPeriod = report.nextPeriod else { return .distantFuture }

    return timeline.countdown.time(at: nextPeriod.tickRange.lowerBound)
  }

  var interruptionTime: Date {
    timeline.countdown.time(at: userActivities.currentTick)
  }
}

extension Interruption {
  var uiAction: UIAction {
    UIAction(title: conciseTitle,
             image: UIImage(systemName: imageName),
             discoverabilityTitle: excuse) { _ in
      Task {
        await MainActor.run {
//          store.receiveAction = .interruptionTapped(self)
        }
      }
    }
  }
}

var progressTimerCancellable: Set<AnyCancellable> = []

extension AppAction {
  var uiAction: UIAction? {
    switch self {
    case .interruptionTapped(let interruption):
      return interruption.uiAction
    default:
      return nil
    }
  }
}

extension UIProgressView {
  func animator(duration: TimeInterval,
                completion: @escaping (UIViewAnimatingPosition) -> Void) -> UIViewPropertyAnimator
  {
    let animator = UIViewPropertyAnimator(duration: duration, curve: .linear, animations: {
      self.alpha = 1.0
      self.setProgress(1.0, animated: true)
    })

    animator.addCompletion(completion)

    return animator
  }
}

extension AppState {
  func timelineIsInterruptedBeforeTimeout(at date: Date) -> Bool {
    // Ensure the has been interrupted otherwise return false

    guard timelineIsInterrupted else {
      return false
    }

    // Ensure the user has met the serious interruption timeout period otherwise return false
    guard pausedToInterruptionTimeout >= 0 else {
      return false
    }

    // Return whether or not the user's preferred serious interruption timeout period has expired
    return timeline.countdown.stopTime.addingTimeInterval(pausedToInterruptionTimeout) > date
  }

  var timelineIsInterrupted: Bool {
    if userActivities.isCountingDown {
      return false
    }

    if timeline.periods.periodAt(userActivities.currentTick).firstTick == userActivities.currentTick {
      return false
    }

    return true
  }
}

// extension AppStore {
//  var menuPopupViewModel: AnyPublisher<RingsPopupMenuState, Never> {
//    $state
//      .map(RingsPopupMenuState.init)
//      .removeDuplicates()
//      .eraseToAnyPublisher()
//  }
// }

// extension AppStore {
//  var resumeSoonProgressBarViewModel: AnyPublisher<ResumeSoonProgressBarViewModel?, Never> {
//    $state
//      .map { ($0.timelineIsInterruptedBeforeTimeout(at: Date())) && ($0.clarifiedInterruption == nil)
//        ? ResumeSoonProgressBarViewModel(isVisible: true)
//        : nil
//      }
//      .removeDuplicates()
//      .eraseToAnyPublisher()
//  }
// }

struct ResumeSoonProgressBarViewModel: Equatable {
  var isVisible: Bool
}

extension SettingsEditorState.PeriodSettings {
  init(timeline: Timeline) {
    self.init(periodDuration: timeline.periods.work,
              shortBreakDuration: timeline.periods.shortBreak,
              longBreakDuration: timeline.periods.longBreak,
              longBreakFrequency: timeline.periods.numWorkPeriods,
              dailyTarget: timeline.dailyTarget,
              pauseBeforeStartingWorkPeriods: timeline.stopOnWork,
              pauseBeforeStartingBreaks: timeline.stopOnBreak,
              resetWorkPeriodOnStop: timeline.resetWorkOnStop)
  }
}

extension AppState {
  var shouldStayAwake: Bool {
    settings.neverSleep && userActivities.isCountingDown
  }
}

extension AppViewController: UNUserNotificationCenterDelegate {
  public func userNotificationCenter(_: UNUserNotificationCenter,
                                     willPresent _: UNNotification) async -> UNNotificationPresentationOptions
  {
    [.banner, .list, .sound]
  }
}

// extension AppStore {
//  var notifications: AnyPublisher<NotificationsUserState, Never> {
//    $state
//      .map(NotificationsUserState.init)
//      .removeDuplicates()
//      .eraseToAnyPublisher()
//  }
// }

struct NotificationsUserState: Equatable {
  let timeline: Timeline
  let currentTick: Tick
  let settings: NotificationsSettingsState
}

private extension NotificationsUserState {
  init(state: AppState) {
    self.init(timeline: state.timeline, currentTick: state.userActivities.currentTick, settings: state.notificationSettings)
  }
}

private func postNotifications(state: AppState) -> Effect {
  .fireAndForget {
    Task {
      do {
        let authorization = try await UNUserNotificationCenter.current()
          .requestAuthorization(options: [.alert, .sound, .providesAppNotificationSettings])

        if authorization == true {
          UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

          let factory = NotificationsFactory()
          let notificationRequests = await factory.makeCountingDownNotifications(for: state.timeline, at: state.userActivities.currentTick)

          for notification in notificationRequests {
            try await UNUserNotificationCenter.current().add(notification)
          }

//            for notification in timeline.makeCountdownPausedSignificantlyNotifications() {
//              try await UNUserNotificationCenter.current().add(notification)
//            }

//            timeline.makeCountdownPausedSignificantlyNotifications()
//              .forEach { notificationRequest in
//                UNUserNotificationCenter.current().add(notificationRequest)
//              }
        }
      } catch {
        print(error)
      }
    }
  }
}
