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

struct AppState {
  var prominentRing: RingIdentifier
  var ringsLayout: RingsViewState.LayoutState
  var user: UserActivityState

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

  init() {
    ringsLayout = .init(portrait: .init(concentricity: 0.0, scaleFactorWhenFullyAcentric: 1.0, scaleFactorWhenFullyConcentric: 1.0, spreadOut: .vertical), landscape: .init(concentricity: 1.0, scaleFactorWhenFullyAcentric: 1.0, scaleFactorWhenFullyConcentric: 1.0, spreadOut: .horizontal))

    prominentRing = .period

    user = UserActivityState(tick: 0, history: [.init()])
  }
}

enum AppAction {
  case prompts(PromptsAction)
  case rings(RingsViewAction)
}

struct AppEnvironment {
  var date: () -> Date
  var scheduler: AnySchedulerOf<RunLoop>
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = Reducer.combine(
  ringsViewReducer.pullback(state: \.rings, action: /AppAction.rings, environment: { RingsEnvironment(date: $0.date) }),

  promptsReducer.pullback(state: \.prompts, action: /AppAction.prompts, environment: { PromptsEnvironment(date: $0.date, scheduler: $0.scheduler) })
)

@MainActor
public class AppViewController: UIViewController {
  let store: Store<AppState, AppAction> = Store(initialState: .init(),
                                                reducer: appReducer,
                                                environment: .init(date: Date.init, scheduler: RunLoop.main.eraseToAnyScheduler()))

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    let ringsView = RingsView(viewStore: ViewStore(store.scope(state: \.rings, action: AppAction.rings)))
    view.host(ringsView) { v, p in
      v.leadingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.leadingAnchor)
      v.trailingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.trailingAnchor)

      v.topAnchor.constraint(equalTo: p.safeAreaLayoutGuide.topAnchor)
    }

    let promptsView = PromptsView(store: store.scope(state: \.prompts, action: AppAction.prompts))

    view.host(promptsView) { v, p in
      v.leadingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.leadingAnchor)
      v.bottomAnchor.constraint(equalTo: p.safeAreaLayoutGuide.bottomAnchor)

      v.topAnchor.constraint(equalTo: ringsView.safeAreaLayoutGuide.bottomAnchor)
      v.trailingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.trailingAnchor)
    }
  }
}
