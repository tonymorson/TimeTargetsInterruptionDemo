import Combine
import Foundation
import SwiftUIKit
import UIKit

public struct NotificationSettingsEditorState: Equatable {
  public var showNotifications: Bool = false
  public var playSound: Bool = true

  public var onStartPeriod: Bool = true
  public var onStartBreak: Bool = true

  public var onLongPause: Bool = true

  public var onHalfwayToDailyTarget: Bool = true
  public var onReachingDailyTarget: Bool = true

  public init(showNotifications: Bool = false, playSound: Bool = true, onStartPeriod: Bool = true, onStartBreak: Bool = true, onLongPause: Bool = true, onHalfwayToDailyTarget: Bool = true, onReachingDailyTarget: Bool = true) {
    self.showNotifications = showNotifications
    self.playSound = playSound
    self.onStartPeriod = onStartPeriod
    self.onStartBreak = onStartBreak
    self.onLongPause = onLongPause
    self.onHalfwayToDailyTarget = onHalfwayToDailyTarget
    self.onReachingDailyTarget = onReachingDailyTarget
  }
}

public enum NotificationSettingsEditorAction: Equatable, Codable {
  case showNotificationsToggled(Bool)
  case playSoundToggled(Bool)
  case onStartPeriodToggled(Bool)
  case onStartBreakToggled(Bool)
  case onLongPauseToggled(Bool)
  case onHalfwayToDailyToggled(Bool)
  case onReachingDailyTargetToggled(Bool)
}

public struct NotificationSettingsEditorEnvironment {
  public init() {}
}

public func notificationSettingsEditorReducer(state: inout NotificationSettingsEditorState,
                                              action: NotificationSettingsEditorAction,
                                              environment _: NotificationSettingsEditorEnvironment)
{
  switch action {
  case let .showNotificationsToggled(value):
    state.showNotifications = value
  case let .playSoundToggled(value):
    state.playSound = value
  case let .onStartPeriodToggled(value):
    state.onStartPeriod = value
  case let .onStartBreakToggled(value):
    state.onStartBreak = value
  case let .onLongPauseToggled(value):
    state.onLongPause = value
  case let .onHalfwayToDailyToggled(value):
    state.onHalfwayToDailyTarget = value
  case let .onReachingDailyTargetToggled(value):
    state.onReachingDailyTarget = value
  }
}

public final class NotificationSettingsEditor: Form<NotificationSettingsEditorState> {
  public var actions: PassthroughSubject<NotificationSettingsEditorAction, Never>!

  public init(userData: AnyPublisher<NotificationSettingsEditorState, Never>) {
    self.actions = PassthroughSubject<NotificationSettingsEditorAction, Never>()

    let actions = actions!

    super.init(userData: userData) { publisher, currentValue in
      Section(header: "Status") {
        ToggleRow(title: "Show Notifications",
                  isOn: publisher.map(\.showNotifications).eraseToAnyPublisher())
        { actions.send(.showNotificationsToggled($0)) }

        if currentValue.showNotifications {
          ToggleRow(title: "Play Sounds",
                    isOn: publisher.map(\.playSound).eraseToAnyPublisher())
          { actions.send(.playSoundToggled($0)) }
        }
      }

      if currentValue.showNotifications {
        Section(header: "Transitioning") {
          Toggle(title: "Ready to start work", isOn: publisher.map(\.onStartPeriod).eraseToAnyPublisher())
            { actions.send(.onStartPeriodToggled($0)) }

          Toggle(title: "Ready for a break", isOn: publisher.map(\.onStartBreak).eraseToAnyPublisher())
            { actions.send(.onStartBreakToggled($0)) }
        }

        Section(header: "Inactivity Reminder", footer: "Shows an alert if countdown paused for too long.") {
          Toggle(title: "Long Pauses", isOn: publisher.map(\.onLongPause).eraseToAnyPublisher())
            { actions.send(.onLongPauseToggled($0)) }
        }

        Section(header: "Significant Progress") {
          Toggle(title: "Halfway", isOn: publisher.map(\.onHalfwayToDailyTarget).eraseToAnyPublisher())
            { actions.send(.onHalfwayToDailyToggled($0)) }

          Toggle(title: "Target Reached", isOn: publisher.map(\.onReachingDailyTarget).eraseToAnyPublisher())
            { actions.send(.onReachingDailyTargetToggled($0)) }
        }
      }
    }
  }
}
