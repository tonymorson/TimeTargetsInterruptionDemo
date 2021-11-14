import Combine
import ComposableArchitecture
import Foundation
import UIKit

public enum TabBarItem { case today, tasks, charts }

public struct TabBarState: Equatable {
  public var selectedTab: TabBarItem

  public init(selectedTab: TabBarItem) {
    self.selectedTab = selectedTab
  }
}

public enum TabBarAction: Equatable {
  case tabTapped(TabBarItem)
}

public let tabbarReducer = Reducer<TabBarState, TabBarAction, Void> { state, action, _ in
  switch action {
  case .tabTapped(let selected):
    state.selectedTab = selected
    return .none
  }
}

public final class TabBarView: UITabBar, UITabBarDelegate {
  private let todayTab = UITabBarItem(title: "Today", image: UIImage(systemName: "star.fill"), tag: 0)
  private let tasksTab = UITabBarItem(title: "Tasks", image: UIImage(systemName: "list.dash"), tag: 1)
  private let chartsTab = UITabBarItem(title: "Charts", image: UIImage(systemName: "chart.pie.fill"), tag: 2)

  var store: ViewStore<TabBarState, TabBarAction>

  public init(store: Store<TabBarState, TabBarAction>) {
    self.store = ViewStore(store)

    super.init(frame: .zero)

    items = [
      todayTab,
      tasksTab,
      chartsTab,
    ]

    delegate = self

    self.store.publisher.map(\.selectedTab).sink { [weak self] in
      guard let self = self else { return }
      switch $0 {
      case .today:
        self.selectedItem = self.todayTab
      case .tasks:
        self.selectedItem = self.tasksTab
      case .charts:
        self.selectedItem = self.chartsTab
      }
    }
    .store(in: &cancellables)
  }

  override public func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)
//    alpha = traitCollection.verticalSizeClass == .compact ? 0.0 : 1.0
  }

  private var cancellables: Set<AnyCancellable> = []

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func sizeThatFits(_ size: CGSize) -> CGSize {
    var sizeThatFits = super.sizeThatFits(size)

    sizeThatFits.height = 120

    return sizeThatFits
  }

  public func tabBar(_: UITabBar, didSelect item: UITabBarItem) {
    let tabItem: TabBarItem

    switch item.title {
    case "Today": tabItem = .today
    case "Tasks": tabItem = .tasks
    case "Charts": tabItem = .charts
    default: fatalError()
    }
    store.send(.tabTapped(tabItem))
  }

  override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

//    alpha = traitCollection.verticalSizeClass == .compact ? 0.0 : 1.0
  }
}
