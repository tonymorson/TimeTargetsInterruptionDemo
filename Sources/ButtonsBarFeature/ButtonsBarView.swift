import Combine
import ComposableArchitecture
import Foundation
import SwiftUIKit
import UIKit

public enum ButtonIdentifier: Equatable {
  public enum Tab: Equatable { case charts, tasks, today }

  case settings, showTab(Tab), tabsModeOff, tabsModeOn
}

public struct ButtonsBarState: Equatable {
  public var isShowingTabs: Bool
  public var selectedTab: ButtonIdentifier.Tab

  public init(isShowingTabs: Bool, selectedTab: ButtonIdentifier.Tab) {
    self.isShowingTabs = isShowingTabs
    self.selectedTab = selectedTab
  }
}

public enum ButtonsBarAction: Equatable {
  case buttonTapped(ButtonIdentifier)
}

public let buttonsBarReducer = Reducer<ButtonsBarState, ButtonsBarAction, Void> { state, action, _ in
  switch action {
  case .buttonTapped(.settings):
    return .none

  case .buttonTapped(.showTab(.charts)):
    state.selectedTab = .charts
    return .none

  case .buttonTapped(.showTab(.tasks)):
    state.selectedTab = .tasks
    return .none

  case .buttonTapped(.showTab(.today)):
    state.selectedTab = .today
    return .none

  case .buttonTapped(.tabsModeOff):
    state.isShowingTabs = false
    return .none

  case .buttonTapped(.tabsModeOn):
    state.isShowingTabs = true
    return .none
  }
}

public final class ButtonsBarView: UIView {
  public init(store: Store<ButtonsBarState, ButtonsBarAction>) {
    viewStore = ViewStore(store)

    super.init(frame: .zero)
  }

  override public func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)
    guard subviews.isEmpty else { return }

    var smallButton = UIButton.Configuration.plain()
    smallButton.buttonSize = .small

    host(settingsButton) { button, parent in
      button.leadingAnchor.constraint(equalTo: parent.leadingAnchor)
      button.topAnchor.constraint(equalTo: parent.topAnchor)
      button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
    }

    host(showUserDataButton) { button, parent in
      button.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
      button.topAnchor.constraint(equalTo: parent.topAnchor)
      button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
    }

    host(hideUserDataButton) { button, parent in
      button.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
      button.topAnchor.constraint(equalTo: parent.topAnchor)
      button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
    }

    host(chartsButton) { button, parent in
      button.trailingAnchor.constraint(equalTo: showUserDataButton.leadingAnchor)
      button.topAnchor.constraint(equalTo: parent.topAnchor)
      button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
    }

    host(tasksButton) { button, parent in
      button.trailingAnchor.constraint(equalTo: chartsButton.leadingAnchor)
      button.topAnchor.constraint(equalTo: parent.topAnchor)
      button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
    }

    host(todayButton) { button, parent in
      button.trailingAnchor.constraint(equalTo: tasksButton.leadingAnchor)
      button.topAnchor.constraint(equalTo: parent.topAnchor)
      button.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
    }

    viewStore.publisher
      .map(\.isShowingTabs)
      .removeDuplicates()
      .sink { [unowned self] in
        hideUserDataButton.isHidden = !$0
        showUserDataButton.isHidden = $0
        updateTabButtons($0)
        self.setNeedsLayout()
        self.layoutIfNeeded()
      }
      .store(in: &cancellables)

    viewStore.publisher
      .map(\.selectedTab)
      .removeDuplicates()
      .sink { [unowned self] selectedTab in
        todayButton.configuration?.background.backgroundColor = .systemBackground
        tasksButton.configuration?.background.backgroundColor = .systemBackground
        chartsButton.configuration?.background.backgroundColor = .systemBackground

        let button: UIButton
        switch selectedTab {
        case .today:
          button = todayButton
        case .tasks:
          button = tasksButton
        case .charts:
          button = chartsButton
        }

        button.configuration?.background.backgroundColor = .tertiarySystemBackground
      }
      .store(in: &cancellables)
  }

  override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    updateTabButtons(viewStore.isShowingTabs)
  }

  private var cancellables: Set<AnyCancellable> = []
  private var viewStore: ViewStore<ButtonsBarState, ButtonsBarAction>

  private func updateTabButtons(_ isShowingTabs: Bool) {
    if traitCollection.verticalSizeClass == .compact {
      todayButton.isHidden = !isShowingTabs
      tasksButton.isHidden = !isShowingTabs
      chartsButton.isHidden = !isShowingTabs
    } else {
      todayButton.isHidden = true
      tasksButton.isHidden = true
      chartsButton.isHidden = true
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  lazy var smallButton: UIButton.Configuration = {
    var smallButton = UIButton.Configuration.plain()
    smallButton.buttonSize = .small

    return smallButton
  }()

  lazy var settingsButton: UIButton = {
    UIButton(configuration: smallButton, primaryAction: viewStore.action(for: .settings))
  }()

  lazy var showUserDataButton: UIButton = {
    let button = UIButton(configuration: smallButton, primaryAction: viewStore.action(for: .tabsModeOn))
    button.transform = CGAffineTransform(rotationAngle: 90 * .pi / 180)

    return button
  }()

  lazy var hideUserDataButton: UIButton = {
    let button = UIButton(configuration: smallButton, primaryAction: viewStore.action(for: .tabsModeOff))
    button.transform = CGAffineTransform(rotationAngle: 90 * .pi / 180)

    return button
  }()

  lazy var chartsButton: UIButton = {
    UIButton(configuration: smallButton, primaryAction: viewStore.action(for: .showTab(.charts)))
  }()

  lazy var todayButton: UIButton = {
    UIButton(configuration: smallButton, primaryAction: viewStore.action(for: .showTab(.today)))
  }()

  lazy var tasksButton: UIButton = {
    UIButton(configuration: smallButton, primaryAction: viewStore.action(for: .showTab(.tasks)))
  }()
}

extension ViewStore where Action == ButtonsBarAction {
  func action(for buttonIdentifier: ButtonIdentifier) -> UIAction {
    let systemName: String
    let discoverabilityTitle: String

    switch buttonIdentifier {
    case .showTab(.charts):
      systemName = "chart.pie"
      discoverabilityTitle = "Show Charts"

    case .showTab(.tasks):
      systemName = "list.dash"
      discoverabilityTitle = "Show Tasks"

    case .showTab(.today):
      systemName = "star"
      discoverabilityTitle = "Show Today"

    case .settings:
      systemName = "gear"
      discoverabilityTitle = "Show Settings"

    case .tabsModeOff:
      systemName = "arrow.down.right.and.arrow.up.left"
      discoverabilityTitle = "Close more"

    case .tabsModeOn:
      systemName = "arrow.up.left.and.arrow.down.right"
      discoverabilityTitle = "Show more"
    }

    return UIAction(image: UIImage(systemName: systemName),
                    discoverabilityTitle: discoverabilityTitle) { _ in
      self.send(.buttonTapped(buttonIdentifier))
    }
  }
}
