import Combine
import ComposableArchitecture
import UIKit
import UIKitReactiveHelpers

public enum ToolbarButtonIdentifier: Equatable {
  public enum TabIdentifier: Int { case today, tasks, charts }

  case settings, showHideTabs, tab(TabIdentifier)
}

public struct ToolbarState: Equatable {
  public var isShowingTabBar: Bool = false
  public var isShowingSettingsEditor: Bool = false
  public var selectedTab: ToolbarButtonIdentifier.TabIdentifier = .today

  public init(isShowingTabBar: Bool, isShowingSettingsEditor: Bool, selectedTab: ToolbarButtonIdentifier.TabIdentifier) {
    self.isShowingTabBar = isShowingTabBar
    self.isShowingSettingsEditor = isShowingSettingsEditor
    self.selectedTab = selectedTab
  }
}

public enum ToolbarAction: Equatable {
  case buttonTapped(ToolbarButtonIdentifier)
}

public let toolbarReducer = Reducer<ToolbarState, ToolbarAction, Void> { state, action, _ in
  switch action {
  case .buttonTapped(.settings):
    state.isShowingSettingsEditor = true

  case .buttonTapped(.showHideTabs):
    state.isShowingTabBar.toggle()

  case .buttonTapped(.tab(.today)):
    state.selectedTab = .today

  case .buttonTapped(.tab(.tasks)):
    state.selectedTab = .tasks

  case .buttonTapped(.tab(.charts)):
    state.selectedTab = .charts
  }

  return .none
}

public final class ToolbarView: UIView {
  @Published private var traits: UITraitCollection = .init()
  private var subscriptions: Set<AnyCancellable> = []
  private let viewStore: ViewStore<ToolbarState, ToolbarAction>

  public init(store: Store<ToolbarState, ToolbarAction>) {
    viewStore = ViewStore(store)

    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func didMoveToSuperview() {
    super.didMoveToSuperview()

    guard subviews.isEmpty else { return }

    // Update traits after setting up all bindings to trigger
    // layout to update after moving to parent view
    defer { traits = traitCollection }

    backgroundColor = .systemBackground

    // MARK: View Creation

    func makeButton(systemName: String) -> UIButton {
      var config = UIButton.Configuration.plain()
      config.buttonSize = .small
      config.image = UIImage(systemName: systemName)

      return UIButton(configuration: config)
    }

    let settingsModalButton = makeButton(systemName: "gear")
    addSubview(settingsModalButton)

    let showTabsPanelModalButton = makeButton(systemName: "sidebar.right")
    addSubview(showTabsPanelModalButton)

    let todayTabButton = makeButton(systemName: "star")
    let tasksTabButton = makeButton(systemName: "list.dash")
    let chartsTabButton = makeButton(systemName: "chart.pie")

    let tabButtons = [todayTabButton, tasksTabButton, chartsTabButton]
    let tabsPanelGroupView = UIStackView(arrangedSubviews: tabButtons)
    tabsPanelGroupView.distribution = .equalSpacing
    tabsPanelGroupView.spacing = 8
    addSubview(tabsPanelGroupView)

    let selectedTabGrayBackgroundView = UIView(frame: .zero)
    selectedTabGrayBackgroundView.backgroundColor = .tertiarySystemFill
    selectedTabGrayBackgroundView.layer.cornerCurve = .continuous
    selectedTabGrayBackgroundView.layer.cornerRadius = 9
    selectedTabGrayBackgroundView.translatesAutoresizingMaskIntoConstraints = false

    tabsPanelGroupView.addSubview(selectedTabGrayBackgroundView)
    tabsPanelGroupView.sendSubviewToBack(selectedTabGrayBackgroundView)

    // MARK: NSLayoutConstraints Creation

    settingsModalButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    [tabsPanelGroupView,
     showTabsPanelModalButton,
     settingsModalButton,
     tasksTabButton,
     chartsTabButton,
     selectedTabGrayBackgroundView].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }

    NSLayoutConstraint.activate([
      showTabsPanelModalButton.lastBaselineAnchor.constraint(equalTo: settingsModalButton.lastBaselineAnchor),
      showTabsPanelModalButton.trailingAnchor.constraint(equalTo: trailingAnchor),
      showTabsPanelModalButton.widthAnchor.constraint(equalToConstant: 44),
//      showTabsPanelModalButton.heightAnchor.constraint(equalToConstant: 44),

      settingsModalButton.topAnchor.constraint(equalTo: topAnchor),
      settingsModalButton.leadingAnchor.constraint(equalTo: leadingAnchor),
      settingsModalButton.widthAnchor.constraint(equalToConstant: 44),
//      settingsModalButton.heightAnchor.constraint(equalToConstant: 44),
    ])

    var selectedTabGrayBackgroundViewConstraints: [[NSLayoutConstraint]] = []

    selectedTabGrayBackgroundViewConstraints.append([
      selectedTabGrayBackgroundView.centerYAnchor.constraint(equalTo: todayTabButton.centerYAnchor),
      selectedTabGrayBackgroundView.centerXAnchor.constraint(equalTo: todayTabButton.centerXAnchor),
    ])

    selectedTabGrayBackgroundViewConstraints.append([
      selectedTabGrayBackgroundView.centerYAnchor.constraint(equalTo: tasksTabButton.centerYAnchor),
      selectedTabGrayBackgroundView.centerXAnchor.constraint(equalTo: tasksTabButton.centerXAnchor),
    ])

    selectedTabGrayBackgroundViewConstraints.append([
      selectedTabGrayBackgroundView.centerYAnchor.constraint(equalTo: chartsTabButton.centerYAnchor),
      selectedTabGrayBackgroundView.centerXAnchor.constraint(equalTo: chartsTabButton.centerXAnchor),
    ])

    selectedTabGrayBackgroundView.heightAnchor.constraint(equalToConstant: 40).isActive = true
    selectedTabGrayBackgroundView.widthAnchor.constraint(equalToConstant: 48).isActive = true

    var tabsPanelGroupViewConstraints: [[NSLayoutConstraint]] = []

    tabsPanelGroupViewConstraints.append([
      tabsPanelGroupView.trailingAnchor.constraint(equalTo: showTabsPanelModalButton.leadingAnchor, constant: -20),
      tabsPanelGroupView.centerYAnchor.constraint(equalTo: showTabsPanelModalButton.centerYAnchor),
    ])

    tabsPanelGroupViewConstraints.append([
      tabsPanelGroupView.trailingAnchor.constraint(equalTo: showTabsPanelModalButton.leadingAnchor, constant: 20),
      tabsPanelGroupView.centerYAnchor.constraint(equalTo: showTabsPanelModalButton.centerYAnchor),
    ])

    // MARK: View Store Bindings

    viewStore.publisher
      .map(\.selectedTab)
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { tab in
        NSLayoutConstraint.deactivate(selectedTabGrayBackgroundViewConstraints[0])
        NSLayoutConstraint.deactivate(selectedTabGrayBackgroundViewConstraints[1])
        NSLayoutConstraint.deactivate(selectedTabGrayBackgroundViewConstraints[2])

        NSLayoutConstraint.activate(selectedTabGrayBackgroundViewConstraints[tab.rawValue])

        self.setNeedsLayout()
        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 1.75) {
          self.layoutIfNeeded()
        }
      }
      .store(in: &subscriptions)

    // Show or hide the tab button depending on the displayMode combined with
    // whether or not we are in vertical compact size.
    Publishers
      .CombineLatest(viewStore.publisher.map(\.isShowingTabBar), $traits.map { $0.verticalSizeClass == .compact })
      .removeDuplicates(by: ==)
      .receive(on: DispatchQueue.main)
      .sink { [unowned self] isShowingTabs, isVerticallyCompact in
        let shouldShowTabs = isShowingTabs && isVerticallyCompact

        NSLayoutConstraint.deactivate(tabsPanelGroupViewConstraints[0])
        NSLayoutConstraint.deactivate(tabsPanelGroupViewConstraints[1])

        NSLayoutConstraint.activate(tabsPanelGroupViewConstraints[shouldShowTabs ? 0 : 1])

        self.setNeedsLayout()
        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 1.75) {
          tabsPanelGroupView.alpha = shouldShowTabs ? 1.0 : 0.0
          self.layoutIfNeeded()
        }
      }
      .store(in: &subscriptions)

    // MARK: UI Actions

    [
      settingsModalButton.publisher(for: .touchUpInside).sink { [unowned self] in
        self.viewStore.send(.buttonTapped(.settings))
      },

      showTabsPanelModalButton.publisher(for: .touchUpInside).sink { [unowned self] in
        self.viewStore.send(.buttonTapped(.showHideTabs))
      },

      todayTabButton.publisher(for: .touchUpInside).sink { [unowned self] in
        self.viewStore.send(.buttonTapped(.tab(.today)))
      },

      tasksTabButton.publisher(for: .touchUpInside).sink { [unowned self] in
        self.viewStore.send(.buttonTapped(.tab(.tasks)))
      },

      chartsTabButton.publisher(for: .touchUpInside).sink { [unowned self] in
        self.viewStore.send(.buttonTapped(.tab(.charts)))
      },
    ]
    .store(in: &subscriptions)
  }

  override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    traits = traitCollection
  }
}

extension Array where Element == AnyCancellable {
  func store(in set: inout Set<AnyCancellable>) {
    set.formUnion(self)
  }
}
