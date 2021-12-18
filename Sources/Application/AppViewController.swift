import Combine
import ComposableArchitecture
import Foundation
import PromptsFeature
import RingsView
import SettingsFeature
import SwiftUI
import SwiftUIKit
import TabBarFeature
import Ticks
import Timeline
import TimelineReports
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

      return .init(isShowingTabBar: isShowingBottomToolbar, isShowingSettingsEditor: isShowingSettings, selectedTab: tab)
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
    view.tintColor = .systemRed

    // Update traits after setting up all bindings to trigger
    // layout to update after moving to parent view
    defer { traits = traitCollection }

    UIView.setAnimationsEnabled(false)
    defer {
      UIView.setAnimationsEnabled(true)
    }

    let toolbar = ToolbarView(store: store.scope(state: \.toolbar, action: AppAction.toolbar))

    view.host(toolbar) { _, _ in
//      toolbar.safeAreaLayoutGuide.topAnchor.constraint(equalTo: host.topAnchor)
//      toolbar.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: host.leadingAnchor)
//      toolbar.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: host.trailingAnchor)
    }

    let ringsView = RingsView(viewStore: ViewStore(store.scope(state: \.rings, action: AppAction.rings)))
    view.host(ringsView) { _, _ in
//      v.leadingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.leadingAnchor)
//      v.trailingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.trailingAnchor)
//
//      v.topAnchor.constraint(equalTo: toolbar.bottomAnchor)
    }

    let promptsView = PromptsView(store: store.scope(state: \.prompts, action: AppAction.prompts))

    view.host(promptsView) { _, _ in
//      v.leadingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.leadingAnchor)
//      v.trailingAnchor.constraint(equalTo: p.safeAreaLayoutGuide.trailingAnchor)
//
      ////      v.topAnchor.constraint(equalTo: ringsView.safeAreaLayoutGuide.bottomAnchor)
      ////      v.bottomAnchor.constraint(equalTo: p.safeAreaLayoutGuide.bottomAnchor)
    }

//    promptVerticalTopConstraint = promptsView.topAnchor.constraint(equalTo: ringsView.safeAreaLayoutGuide.bottomAnchor)
//    promptVerticalBottomConstraint = promptsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
//
//    promptVerticalTopConstraint.isActive = true
//    promptVerticalBottomConstraint.isActive = true

    let tabBar = TabBarView(store: store.scope(state: \.tabBar, action: AppAction.tabBar))

    view.host(tabBar) { _, _ in
//      v.leadingAnchor.constraint(equalTo: p.leadingAnchor)
//      v.trailingAnchor.constraint(equalTo: p.trailingAnchor)

//      v.bottomAnchor.constraint(equalTo: p.safeAreaLayoutGuide.bottomAnchor)
    }

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
    label.text = "Today"
    label.font = .preferredFont(forTextStyle: .title2, compatibleWith: traitCollection)
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)

    let subtitle = UILabel()
    subtitle.text = "Rangsit"
    subtitle.font = .preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)
    subtitle.textColor = .secondaryLabel
    subtitle.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(subtitle)

    // Create and subview constraints
    NSLayoutConstraint.activate([
      toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
      toolbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
      toolbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
//      toolbar.heightAnchor.constraint(equalToConstant: 44),
    ])

    NSLayoutConstraint.activate([
      verticalStackView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
      verticalStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
      verticalStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
      verticalStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
    ])

    let promptsViewShowing = [
      promptsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      promptsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
      promptsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
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
    label.leadingAnchor.constraint(equalTo: ringsView.trailingAnchor, constant: 10).isActive = true

    subtitle.topAnchor.constraint(equalTo: label.bottomAnchor).isActive = true
    subtitle.leadingAnchor.constraint(equalTo: label.leadingAnchor).isActive = true

    NSLayoutConstraint.activate(promptsViewShowing)

    // Reactive Layouts

    viewStore.publisher.map(\.isShowingBottomToolbar)
      .receive(on: DispatchQueue.main)
      .sink { value in
        NSLayoutConstraint.deactivate(promptsViewHidden)
        NSLayoutConstraint.deactivate(promptsViewShowing)

        NSLayoutConstraint.activate(value ? promptsViewHidden : promptsViewShowing)

        self.view.setNeedsLayout()

        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 1.75) {
          self.view.layoutIfNeeded()
        }
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

    lazy var sidePanelTitle: AnyPublisher<String, Never> = {
      viewStore.publisher
        .map(\.selectedTab)
        .map {
          switch $0 {
          case .today:
            return "Today"
          case .tasks:
            return "Tasks"
          case .charts:
            return "Charts"
          }
        }
        .eraseToAnyPublisher()
    }()

    lazy var sidePanelSubitle: AnyPublisher<String, Never> = {
      viewStore.publisher
        .map(\.selectedTab)
        .map {
          switch $0 {
          case .today:
            return "Rangsit"
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

    sidePanelSubitle
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
          .sink { [unowned editorViewController] theme in
            switch theme {
            case .none:
              self.overrideUserInterfaceStyle = .unspecified
              editorViewController.overrideUserInterfaceStyle = .unspecified
            case .light:
              self.overrideUserInterfaceStyle = .light
              editorViewController.overrideUserInterfaceStyle = .light
            case .dark:
              self.overrideUserInterfaceStyle = .dark
              editorViewController.overrideUserInterfaceStyle = .dark
            }
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
