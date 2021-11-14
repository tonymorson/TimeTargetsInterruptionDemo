import ButtonsBarFeature
import Combine
import ComposableArchitecture
import Foundation
import PromptsFeature
import RingsView
import SwiftUIKit
import TabBarFeature
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

  var tabBar: TabBarState {
    get {
      let tab: TabBarItem
      switch selectedTab {
      case .tasks: tab = .tasks
      case .charts: tab = .charts
      case .today: tab = .today
      }

      return .init(selectedTab: tab)
    }
    set {
      switch newValue.selectedTab {
      case .today:
        selectedTab = .today
      case .tasks:
        selectedTab = .tasks
      case .charts:
        selectedTab = .charts
      }
    }
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
  case tabBar(TabBarAction)
  case toolbar(ButtonsBarAction)
}

struct AppEnvironment {
  var date: () -> Date
  var scheduler: AnySchedulerOf<RunLoop>
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = Reducer.combine(
  ringsViewReducer.pullback(state: \.rings, action: /AppAction.rings, environment: { RingsEnvironment(date: $0.date) }),

  promptsReducer.pullback(state: \.prompts, action: /AppAction.prompts, environment: { PromptsEnvironment(date: $0.date, scheduler: $0.scheduler) }),

  buttonsBarReducer.pullback(state: \.toolbar, action: /AppAction.toolbar, environment: { _ in () }),

  tabbarReducer.pullback(state: \.tabBar, action: /AppAction.tabBar, environment: { _ in () })
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
      v.trailingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.trailingAnchor)

//      v.topAnchor.constraint(equalTo: ringsView.safeAreaLayoutGuide.bottomAnchor)
//      v.bottomAnchor.constraint(equalTo: p.safeAreaLayoutGuide.bottomAnchor)
    }

    promptVerticalTopConstraint = promptsView.topAnchor.constraint(equalTo: ringsView.safeAreaLayoutGuide.bottomAnchor)
    promptVerticalBottomConstraint = promptsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

    promptVerticalTopConstraint.isActive = true
    promptVerticalBottomConstraint.isActive = true

    let tabBar = TabBarView(store: store.scope(state: \.tabBar, action: AppAction.tabBar))

    view.host(tabBar) { v, p in
      v.leadingAnchor.constraint(equalTo: p.leadingAnchor)
      v.trailingAnchor.constraint(equalTo: p.trailingAnchor)

//      v.bottomAnchor.constraint(equalTo: p.safeAreaLayoutGuide.bottomAnchor)
    }

    tabBarVerticalConstraint = tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)

    tabBarVerticalConstraint.isActive = true

    viewStore.publisher
      .map(\.isShowingBottomToolbar)
      .removeDuplicates()
      .dropFirst()
      .sink { isShowingTabs in
        self.view.setNeedsLayout()
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
          promptsView.alpha = isShowingTabs ? 0.0 : 1.0
          self.view.layoutIfNeeded()
        }
      }
      .store(in: &cancellables)
  }

  override public func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    var constant: CGFloat = viewStore.isShowingBottomToolbar ? 0 : 250
    if traitCollection.verticalSizeClass == .compact {
      constant = 250
    }

    tabBarVerticalConstraint.constant = constant

    if viewStore.isShowingBottomToolbar {
      promptVerticalTopConstraint.constant = 250
      promptVerticalBottomConstraint.constant = 250
    } else {
      promptVerticalTopConstraint.constant = 0
      promptVerticalBottomConstraint.constant = 0
    }
  }

  override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)

    view.setNeedsLayout()

    coordinator.animate(alongsideTransition: { [unowned self] _ in
      self.view.layoutIfNeeded()
    }) { [unowned self] _ in
      self.view.layoutIfNeeded()
    }
  }

  private var cancellables: Set<AnyCancellable> = []
  private var tabBarVerticalConstraint: NSLayoutConstraint!
  private var promptVerticalTopConstraint: NSLayoutConstraint!
  private var promptVerticalBottomConstraint: NSLayoutConstraint!
}
