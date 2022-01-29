import Combine
import ComposableArchitecture
import Foundation
import PromptsFeature
import RingsView
import SettingsFeature
import SwiftUI
import TabBarFeature
import Timeline
import ToolbarFeature
import UIKit
import UserActivity

enum NavigationAction {
  case dismiss
}

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

  var toolbar: ToolbarState {
    get {
      let tab: ToolbarButtonIdentifier.TabIdentifier
      switch selectedTab {
      case .tasks: tab = .tasks
      case .charts: tab = .charts
      case .today: tab = .today
      }

      return .init(isShowingTabBar: isShowingBottomToolbar,
                   isShowingSettingsEditor: isShowingSettings,
                   selectedTab: tab)
    }
    set {
      isShowingSettings = newValue.isShowingSettingsEditor
      isShowingBottomToolbar = newValue.isShowingTabBar
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
  
  var periodBars: [SessionViewContent] {
    let targetTick = timeline.periods.targetTick(at: 0, workPeriodsPerDay: timeline.dailyTarget)
    
    let lastPeriodTick = max (targetTick, timeline.periods.periodAt(tick).lastTick)
    
    let periods = timeline.periods.periods(from: 0, to: lastPeriodTick)
    
    let periodData = periods.filter(\.isWorkPeriod).map { period -> PeriodBarContent in
      let percentage = period.tickRange.progress(at: tick)
      
      let session = timeline.periods.sessionAt(period.lastTick).periods
      
      let fillColor: Color
      if tick >= targetTick {
        fillColor = .yellow
      } else {
        let progress = session.workProgress(at: tick)
        
        fillColor = progress < 1.0 ? .red : .green
      }
      
      return PeriodBarContent(percentage: percentage,
                              fillColor: fillColor,
                              isGlowing: false,
                              isPulsing: false,
                              id: period.firstTick)
    }
    
    return [SessionViewContent(periods: periodData, id: 0)]
  
  }

  init() {
    ringsLayout = .init(portrait: .init(concentricity: 0.0,
                                        scaleFactorAcentric: 1.0,
                                        scaleFactorConcentric: 1.0,
                                        acentricSpread: .vertical),
                        
                        landscape: .init(concentricity: 1.0,
                                         scaleFactorAcentric: 1.0,
                                         scaleFactorConcentric: 1.0,
                                         acentricSpread: .horizontal))

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
  case toolbar(ToolbarAction)
  case navigation(NavigationAction)
}

struct AppEnvironment {
  var date: () -> Date
  var scheduler: AnySchedulerOf<RunLoop>
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = Reducer.combine(
  ringsViewReducer.pullback(state: \.rings, action: /AppAction.rings, environment: { RingsEnvironment(date: $0.date) }),

  promptsReducer.pullback(state: \.prompts, action: /AppAction.prompts, environment: { PromptsEnvironment(date: $0.date, scheduler: $0.scheduler) }),

  toolbarReducer.pullback(state: \.toolbar, action: /AppAction.toolbar, environment: { _ in () }),

  tabbarReducer.pullback(state: \.tabBar, action: /AppAction.tabBar, environment: { _ in () }),

  Reducer { state, action, _ in
    switch action {
    case .navigation(.dismiss):
      state.isShowingSettings = false

    default:
      break
    }
    return .none
  }
)

@MainActor
public class AppViewController: UIViewController {
  @Published private var traits: UITraitCollection = .init()

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
//    
//    let controller = UIHostingController(rootView: Home())
//    addChild(controller)
//    controller.view.translatesAutoresizingMaskIntoConstraints = false
//    
//    view.addSubview(controller.view)
//
//    NSLayoutConstraint.activate([
//      view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
//      view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
//      view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
//      view.topAnchor.constraint(equalTo: controller.view.topAnchor),
//    ])
//
//    controller.didMove(toParent: self)
//    
//    return
    view.tintColor = .systemRed

    // Update traits after setting up all bindings to trigger
    // layout to update after moving to parent view
    defer { traits = traitCollection }

    UIView.setAnimationsEnabled(false)
    defer {
      UIView.setAnimationsEnabled(true)
    }

    let toolbar = ToolbarView(store: store.scope(state: \.toolbar, action: AppAction.toolbar))
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(toolbar)

    let ringsView = RingsView(viewStore: ViewStore(store.scope(state: \.rings, action: AppAction.rings)))
    ringsView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(ringsView)

    let promptsView = PromptsView(store: store.scope(state: \.prompts, action: AppAction.prompts))
    promptsView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(promptsView)
    
    let taskTitle = UILabel()
    taskTitle.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(taskTitle)
    
    taskTitle.text = "Task 1"
    
    let periodBars = UIHostingController(rootView: PeriodBars(sessions: ViewStore(store.scope(state: \.periodBars, action: { _ in fatalError() }))))
    addChild(periodBars)
    periodBars.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(periodBars.view)
    periodBars.didMove(toParent: self)

    NSLayoutConstraint.activate([
      taskTitle.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
      taskTitle.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
//      toolbar.heightAnchor.constraint(equalToConstant: 44),
    ])
    

//    promptVerticalTopConstraint = promptsView.topAnchor.constraint(equalTo: ringsView.safeAreaLayoutGuide.bottomAnchor)
//    promptVerticalBottomConstraint = promptsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
//
//    promptVerticalTopConstraint.isActive = true
//    promptVerticalBottomConstraint.isActive = true

    let tabBar = TabBarView(store: store.scope(state: \.tabBar, action: AppAction.tabBar))
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabBar)

    let verticalStackView = UIStackView()
    verticalStackView.translatesAutoresizingMaskIntoConstraints = false
    verticalStackView.axis = .vertical

    let horizontalStackView = UIStackView()
    horizontalStackView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(verticalStackView)
    verticalStackView.addArrangedSubview(horizontalStackView)
    verticalStackView.distribution = .equalSpacing

    verticalStackView.addArrangedSubview(UIView())

    horizontalStackView.addArrangedSubview(ringsView)
    horizontalStackView.distribution = .equalSpacing
    ringsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
    ringsView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true

    let label = UILabel()
    label.text = ""
    label.font = .preferredFont(forTextStyle: .caption1, compatibleWith: traitCollection)
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)

    let subtitle = UILabel()
    subtitle.text = ""
    subtitle.font = .preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)
    subtitle.textColor = .secondaryLabel
    subtitle.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(subtitle)

    NSLayoutConstraint.activate([
      periodBars.view.leadingAnchor.constraint(equalTo: subtitle.leadingAnchor),
      periodBars.view.topAnchor.constraint(equalTo: subtitle.topAnchor, constant: 4),
//      toolbar.heightAnchor.constraint(equalToConstant: 44),
    ])

//    label.isHidden = true
    subtitle.isHidden = true
    // Create and subview constraints
    let top = toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
    top.priority = .init(999)
    NSLayoutConstraint.activate([
      top,
      toolbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
      toolbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
//      toolbar.heightAnchor.constraint(equalToConstant: 44),
    ])

    NSLayoutConstraint.activate([
      verticalStackView.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 20),
      verticalStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
      verticalStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
      verticalStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -84),
    ])

    let promptsViewShowing = [
      promptsView.bottomAnchor.constraint(equalTo: view.readableContentGuide.bottomAnchor, constant: -20),
      promptsView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: 10),
      promptsView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor, constant: -10),
      promptsView.heightAnchor.constraint(equalToConstant: 44),
    ]

    let promptsViewHidden = [
      promptsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 200),
      promptsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
      promptsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
      promptsView.heightAnchor.constraint(equalToConstant: 44),
    ]

    let showingTabBarContraints = [
      tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ]

    let hiddenTabBarContraints = [
      tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 100),
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ]

    label.topAnchor.constraint(equalTo: ringsView.topAnchor).isActive = true
    label.leadingAnchor.constraint(equalTo: ringsView.trailingAnchor, constant: 20).isActive = true

    subtitle.topAnchor.constraint(equalTo: label.bottomAnchor).isActive = true
    subtitle.leadingAnchor.constraint(equalTo: label.leadingAnchor).isActive = true

    NSLayoutConstraint.activate(promptsViewShowing)
    
    view.bringSubviewToFront(promptsView)
    view.bringSubviewToFront(tabBar)

    // Reactive Layouts

    viewStore.publisher.map(\.isShowingBottomToolbar)
      .receive(on: DispatchQueue.main)
      .sink { value in
        NSLayoutConstraint.deactivate(promptsViewHidden)
        NSLayoutConstraint.deactivate(promptsViewShowing)

        NSLayoutConstraint.activate(value ? promptsViewHidden : promptsViewShowing)

        self.view.setNeedsLayout()

        UIView.animate(withDuration: 0.35) {
          self.view.layoutIfNeeded()
        }
        
//        UIView.animate(withDuration: 0.35,
//                       delay: 0,
//                       usingSpringWithDamping: 0.8,
//                       initialSpringVelocity: 1.75) {
//          self.view.layoutIfNeeded()
//        }
      }
      .store(in: &cancellables)

    viewStore.publisher
      .map(\.isShowingBottomToolbar)
      .receive(on: DispatchQueue.main)
      .sink {
        let isShowing = $0
        if horizontalStackView.arrangedSubviews.count == 1, $0 {
          horizontalStackView.alignment = .top

          horizontalStackView.addArrangedSubview(UIView())
        } else if horizontalStackView.arrangedSubviews.count == 2, !$0 {
          let view = horizontalStackView.arrangedSubviews.last!
          horizontalStackView.removeArrangedSubview(view)
          view.removeFromSuperview()
          horizontalStackView.alignment = .fill
        }

        if verticalStackView.arrangedSubviews.count == 1, $0 {
          verticalStackView.alignment = .leading

          verticalStackView.addArrangedSubview(UIView())
        } else if verticalStackView.arrangedSubviews.count == 2, !$0 {
          verticalStackView.alignment = .fill
          let view = verticalStackView.arrangedSubviews.last!
          verticalStackView.removeArrangedSubview(view)
          view.removeFromSuperview()
        }

        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 1.75) {
          label.alpha = isShowing ? 1.0 : 0.0
          subtitle.alpha = isShowing ? 1.0 : 0.0
          self.view.layoutIfNeeded()
        }
        
        var v = self.view.viewWithTag(1002)
          if v == nil {
            v = UIView()
            v!.tag = 1002
//            v!.backgroundColor = .yellow
            v!.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.addSubview(v!)
            

            self.view.sendSubviewToBack(v!)
            NSLayoutConstraint.activate([
              v!.leadingAnchor.constraint(equalTo: verticalStackView.leadingAnchor),
              v!.trailingAnchor.constraint(equalTo: verticalStackView.trailingAnchor),
              v!.topAnchor.constraint(equalTo: horizontalStackView.bottomAnchor),
              v!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
              
            ])
            
            let taskListView = TaskList()
            let taskList = UIHostingController(rootView: taskListView)
            self.addChild(taskList)
            taskList.view.translatesAutoresizingMaskIntoConstraints = false
            v!.addSubview(taskList.view)

            NSLayoutConstraint.activate([
              v!.leadingAnchor.constraint(equalTo: taskList.view.leadingAnchor),
              v!.trailingAnchor.constraint(equalTo: taskList.view.trailingAnchor),
              v!.topAnchor.constraint(equalTo: taskList.view.topAnchor, constant: -20),
              //              v!.bottomAnchor.constraint(equalTo: taskList.view.bottomAnchor),
              taskList.view.heightAnchor.constraint(equalToConstant: 800),


            ])
            
            self.view.bringSubviewToFront(taskList.view)

            
          }
        
//        v!.alpha = isShowing ? 1.0 : 0.0

        
        
      }
      .store(in: &cancellables)

    // Combine tab bar mode with the current trait collection
    // and show or hide the tab bar as needed depending on device
    // orientation
    Publishers.CombineLatest(
      viewStore.publisher.map(\.isShowingBottomToolbar),
      $traits.map { $0.verticalSizeClass == .compact }
    )
    .map { $0 && !$1 }
    .map { $0 ? 1.0 : 0.0 }
    .receive(on: DispatchQueue.main)
    .sink { value in
      NSLayoutConstraint.deactivate(hiddenTabBarContraints)
      NSLayoutConstraint.deactivate(showingTabBarContraints)

      NSLayoutConstraint.activate(value == 1.0 ? showingTabBarContraints : hiddenTabBarContraints)

      self.view.setNeedsLayout()

      UIView.animate(withDuration: 0.35,
                     delay: 0,
                     usingSpringWithDamping: 0.6,
                     initialSpringVelocity: 1.75) {
        tabBar.alpha = value
        self.view.layoutIfNeeded()
      }
    }
    .store(in: &cancellables)
    
    viewStore.publisher.map(\.isShowingBottomToolbar)
    .receive(on: DispatchQueue.main)
    .sink { value in
      UIView.animate(withDuration: 0.35,
                     delay: 0,
                     usingSpringWithDamping: 0.6,
                     initialSpringVelocity: 1.75) {
        taskTitle.alpha = value ? 0.0 : 1.0
      }
    }
    .store(in: &cancellables)

    lazy var sidePanelTitle: AnyPublisher<String, Never> = {
      viewStore.publisher
        .map(\.selectedTab)
        .map {
          switch $0 {
          case .today:
            return "WORK PERIODS"
          case .tasks:
            return "Tasks"
          case .charts:
            return "Charts"
          }
        }
        .eraseToAnyPublisher()
    }()

    lazy var sidePanelSubtitle: AnyPublisher<String, Never> = {
      viewStore.publisher
        .map(\.selectedTab)
        .map {
          switch $0 {
          case .today:
            return "Task 1"
          case .tasks:
            return "Blackley"
          case .charts:
            return "Port Charlotte"
          }
        }
        .eraseToAnyPublisher()
    }()

    sidePanelTitle
      .removeDuplicates()
      .sink { text in
        label.text = text
        label.superview?.setNeedsLayout()
        label.superview?.layoutIfNeeded()
      }
      .store(in: &cancellables)

    sidePanelSubtitle
      .removeDuplicates()
      .sink { text in
        subtitle.text = text
        subtitle.superview?.setNeedsLayout()
        subtitle.superview?.layoutIfNeeded()
      }
      .store(in: &cancellables)

    viewStore.publisher
      .map(\.isShowingSettings)
      .removeDuplicates()
      .sink { isShowingSettings in
        guard self.presentedViewController == nil
        else { return }

        guard isShowingSettings
        else { return }

        let editor = SettingsEditor()
        let editorViewController = DismissingHostingController(rootView: AnyView(editor)) {
          self.viewStore.send(.navigation(.dismiss))
        }
        //                    if self.presentedViewController == nil {
        //                      let filteredSettings = store.settings.filter { $0 != nil }
        //                        .map { $0! }
        //                        .eraseToAnyPublisher()
        //
        //                      let editor = SettingsEditor(state: filteredSettings)
        //                      editor.onDismiss = { store.receiveAction = .navigation(.settingsEditorDismissed) }
        //
        self.present(editorViewController, animated: true)

        editor.value.$settings.map(\.theme)
          .sink { [weak editorViewController] theme in
            self.overrideUserInterfaceStyle = theme.map(UIUserInterfaceStyle.init) ?? .unspecified
            editorViewController?.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
          }
          .store(in: &self.cancellables)

        //
        //                      (editor.viewControllers.first)?
        //                        .navigationBarItems(leading: { BarButtonItem(.cancel) { store.receiveAction = .navigation(.settingsEditorDismissed) } })
        //                        .navigationBarItems(trailing: { BarButtonItem(.done) { store.receiveAction = .navigation(.settingsEditorDismissed) } })
        //
        //                      editor.sentActions
        //                        .map(AppAction.settingsEditor)
        //                        .assign(to: &store.$receiveAction)
        //                    }
      }
      .store(in: &cancellables)
  }

  override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    traits = traitCollection
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

final class DismissingHostingController: UIHostingController<AnyView> {
  var onDeinit: () -> Void

  init(rootView: AnyView, onDeinit: @escaping () -> Void) {
    self.onDeinit = onDeinit
    super.init(rootView: rootView)
  }

  @available(*, unavailable)
  @MainActor @objc dynamic required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    onDeinit()
  }
}


import SwiftUI

struct Home : View {
  var body: some View {
    GeometryReader { geometry in
      
      if geometry.size.width > geometry.size.height {
        HStack {
          VStack {
            Rectangle().aspectRatio(1, contentMode: .fit).foregroundColor(.red).id(1)
            Rectangle().aspectRatio(1, contentMode: .fit).foregroundColor(.green).id(2)
          }
          Spacer()
          Rectangle().foregroundColor(.yellow)
        }
      } else {
        VStack {
          HStack {
            Rectangle().aspectRatio(1, contentMode: .fit).foregroundColor(.red).id(1)
            Rectangle().aspectRatio(1, contentMode: .fit).foregroundColor(.green).id(2)
          }
          Spacer()
          Rectangle().foregroundColor(.yellow)
        }
      }
    }
  }
}
