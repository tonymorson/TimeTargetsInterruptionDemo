import Combine
import ComposableArchitecture
import Foundation
import UIKit

public final class PromptsView: UIButton {
  private var cancellables: Set<AnyCancellable> = []
  private let viewStore: ViewStore<ViewState, ViewAction>

  struct ViewState: Equatable {
    let title: AttributedString
    let subtitle: AttributedString
    let actions: [ViewAction.TimelineAction]
    let shouldIncludeInterruptionsInPopupMenu: Bool

    init(state: PromptsState) {
      let prompts = state.prompts

      var title = AttributedString(prompts.0.isEmpty ? " " : prompts.0)
      title.font = UIFont.systemFont(ofSize: 24, weight: .light).rounded()
      title.foregroundColor = .systemRed

      var subtitle = AttributedString(prompts.1.isEmpty ? " " : prompts.1)
      subtitle.font = UIFont.systemFont(ofSize: 18, weight: .light).rounded()
      subtitle.foregroundColor = .label

      let timelineActionMenuItems = state.timelineActionMenuItems

      self.title = title
      self.subtitle = subtitle
      actions = timelineActionMenuItems
      shouldIncludeInterruptionsInPopupMenu = state.isTimelineInterrupted
    }
  }

  enum ViewAction: Equatable {
    enum TimelineAction {
      case pauseBreak
      case pauseWorkPeriod

      case skipToNextBreak
      case skipToNextWorkPeriod

      case startBreak
      case startWorkPeriod
      case startSchedule

      case restartBreak
      case restartWorkPeriod

      case resumeBreak
      case resumeWorkPeriod
    }

    case timeline(TimelineAction)
    case interruptionTapped(Interruption)
  }

  public init(store: Store<PromptsState, PromptsAction>) {
    viewStore = ViewStore(store.scope(state: ViewState.init, action: PromptsAction.init))
    super.init(frame: .zero)

    backgroundColor = .systemBackground

    var configuration = UIButton.Configuration.gray()
    configuration.cornerStyle = .dynamic
    configuration.baseForegroundColor = UIColor.systemRed
    configuration.baseBackgroundColor = .clear
    configuration.buttonSize = .medium

    configuration.titlePadding = 4
    configuration.titleAlignment = .center

    self.configuration = configuration
    showsMenuAsPrimaryAction = true

    titleLabel?.adjustsFontSizeToFitWidth = true
    subtitleLabel?.adjustsFontSizeToFitWidth = true

    titleLabel?.numberOfLines = 1
    subtitleLabel?.numberOfLines = 1

    viewStore.publisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        guard let self = self else { return }

        // https://stackoverflow.com/questions/3073520/animate-text-change-in-uilabel
        let animation = CATransition()

        var discard = AttributedString(" ")
        discard.font = UIFont.systemFont(ofSize: 24, weight: .light).rounded()
        discard.foregroundColor = .systemRed

        let interval = state.title == discard
          ? 2.0
          : 0.15

        animation.duration = interval
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.layer.add(animation, forKey: nil)

        self.configuration?.attributedTitle = state.title
        self.configuration?.attributedSubtitle = state.subtitle
      }
      .store(in: &cancellables)

    viewStore.publisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .map { ($0.actions, $0.shouldIncludeInterruptionsInPopupMenu) }
      .removeDuplicates(by: ==)
      .map { actions, shouldIncludeInterruptionSubMenu -> [UIMenuElement] in
        var menuItems: [UIMenuElement] = []

        if shouldIncludeInterruptionSubMenu {
          let logInterruptionMenu = UIMenu(options: .displayInline,
                                           children: [UIMenu(title: "Clarify Interruption...",
                                                             image: UIImage(systemName: "pencil"),
                                                             children: [
                                                               Interruption.conversation.asUIAction(self.viewStore),
                                                               Interruption.email.asUIAction(self.viewStore),
                                                               Interruption.socialMedia.asUIAction(self.viewStore),
                                                               Interruption.daydreaming.asUIAction(self.viewStore),
                                                               Interruption.phone.asUIAction(self.viewStore),
                                                               Interruption.message.asUIAction(self.viewStore),

                                                               UIMenu(title: "More...", children: [
                                                                 Interruption.tired.asUIAction(self.viewStore),
                                                                 Interruption.finished.asUIAction(self.viewStore),
                                                                 Interruption.lunch.asUIAction(self.viewStore),
                                                                 Interruption.other.asUIAction(self.viewStore),
                                                                 Interruption.restroom.asUIAction(self.viewStore),
                                                                 Interruption.underTheWeather.asUIAction(self.viewStore),
                                                                 Interruption.health.asUIAction(self.viewStore),
                                                                 Interruption.meeting.asUIAction(self.viewStore),
                                                                 Interruption.powerFailure.asUIAction(self.viewStore),
                                                               ].reversed()),

                                                             ].reversed())])

          menuItems += [logInterruptionMenu]
        }

        menuItems +=
          actions.map { action in
            UIAction(title: action.menuTitle,
                     image: UIImage(systemName: action.menuImageName ?? ""),
                     discoverabilityTitle: action.menuTitle) { _ in
              self.viewStore.send(.timeline(action))
            }
          }

        return menuItems
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] menuItems in
        guard let self = self else { return }
        self.menu = UIMenu(children: menuItems)
      }
      .store(in: &cancellables)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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

extension Interruption {
  func asUIAction(_ store: ViewStore<PromptsView.ViewState, PromptsView.ViewAction>) -> UIAction {
    UIAction(title: conciseTitle,
             image: UIImage(systemName: imageName),
             discoverabilityTitle: excuse) { _ in
      Task {
        await MainActor.run {
          store.send(.interruptionTapped(self))
        }
      }
    }
  }
}
