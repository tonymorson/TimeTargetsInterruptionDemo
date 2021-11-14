import ButtonsBarFeature
import Combine
import ComposableArchitecture
import Foundation
import PromptsFeature
import RingsView
import SwiftUIKit
import Ticks
import Timeline
import TimelineReports
import UIKit
import UserActivity

struct AppState: Equatable {
  enum Tab { case tasks, charts, today }
  var prominentRing: RingIdentifier
  var ringsLayout: RingsViewState.LayoutState
  var user: UserActivityState
  var (isShowingBottomToolbar, selectedTab): (Bool, Tab)
  var isShowingSettings: Bool

  var prompts: PromptsState {
    get { .init(userActivity: user) }
    set { user = newValue.userActivity }
  }

  var rings: RingsViewState {
    get {
      .init(content: RingsViewState.ContentState(tick: tick, timeline: timeline),
            layout: ringsLayout,
            prominentRing: prominentRing)
    }
    set {
      if user.history.last != newValue.content.timeline {
        user.history.append(newValue.content.timeline)
      }
      user.tick = newValue.content.tick
      ringsLayout = newValue.layout
      prominentRing = newValue.prominentRing
    }
  }

  var tick: Tick {
    user.tick
  }

  var timeline: Timeline {
    user.history.last ?? .init()
  }

  var toolbar: ButtonsBarState {
    get {
      let tab: ButtonIdentifier.Tab
      switch selectedTab {
      case .tasks: tab = .tasks
      case .charts: tab = .charts
      case .today: tab = .today
      }

      return .init(isShowingTabs: isShowingBottomToolbar,
                   selectedTab: tab)
    }
    set {
      isShowingBottomToolbar = newValue.isShowingTabs
      switch newValue.selectedTab {
      case .charts:
        selectedTab = .charts
      case .tasks:
        selectedTab = .tasks
      case .today:
        selectedTab = .today
      }
    }
  }

  init() {
    ringsLayout = .init(portrait: .init(concentricity: 0.0, scaleFactorAcentric: 1.0, scaleFactorConcentric: 1.0, acentricSpread: .vertical), landscape: .init(concentricity: 1.0, scaleFactorAcentric: 1.0, scaleFactorConcentric: 1.0, acentricSpread: .horizontal))

    prominentRing = .period

    user = UserActivityState(tick: 0, history: [.init()])

    isShowingBottomToolbar = false
    isShowingSettings = false

    selectedTab = .today
  }
}

enum AppAction {
  case prompts(PromptsAction)
  case rings(RingsViewAction)
  case toolbar(ButtonsBarAction)
}

struct AppEnvironment {
  var date: () -> Date
  var scheduler: AnySchedulerOf<RunLoop>
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = Reducer.combine(
  ringsViewReducer.pullback(state: \.rings, action: /AppAction.rings, environment: { RingsEnvironment(date: $0.date) }),

  promptsReducer.pullback(state: \.prompts, action: /AppAction.prompts, environment: { PromptsEnvironment(date: $0.date, scheduler: $0.scheduler) }),

  buttonsBarReducer.pullback(state: \.toolbar, action: /AppAction.toolbar, environment: { _ in () })
)

@MainActor
public class AppViewController: UIViewController {
  let store: Store<AppState, AppAction> = Store(initialState: .init(),
                                                reducer: appReducer,
                                                environment: .init(date: Date.init, scheduler: RunLoop.main.eraseToAnyScheduler()))

  lazy var viewStore: ViewStore<AppState, AppAction> = {
    ViewStore(store)
  }()

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

    let toolbar = ButtonsBarView(store: store.scope(state: \.toolbar,
                                                    action: AppAction.toolbar))

    view.host(toolbar) { host, toolbar in
      toolbar.safeAreaLayoutGuide.topAnchor.constraint(equalTo: host.topAnchor)
      toolbar.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: host.leadingAnchor)
      toolbar.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: host.trailingAnchor)
    }

    let ringsView = RingsView(viewStore: ViewStore(store.scope(state: \.rings, action: AppAction.rings)))
    view.host(ringsView) { v, p in
      v.leadingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.leadingAnchor)
      v.trailingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.trailingAnchor)

      v.topAnchor.constraint(equalTo: toolbar.bottomAnchor)
    }

    let promptsView = PromptsView(store: store.scope(state: \.prompts, action: AppAction.prompts))

    view.host(promptsView) { v, p in
      v.leadingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.leadingAnchor)
      v.bottomAnchor.constraint(equalTo: p.safeAreaLayoutGuide.bottomAnchor)

      v.topAnchor.constraint(equalTo: ringsView.safeAreaLayoutGuide.bottomAnchor)
      v.trailingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.trailingAnchor)
    }

    viewStore.publisher.map(\.isShowingBottomToolbar).sink { isShowingTabs in
      promptsView.isHidden = isShowingTabs
    }
    .store(in: &cancellables)
  }

  private var cancellables: Set<AnyCancellable> = []
}
