import Combine
import Foundation
import SwiftUIKit
import UIKit

public struct NotificationSettingsEditorState: Hashable, Equatable {
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

public enum NotificationSettingsEditorAction {
  case showNotificationsToggled(Bool)
  case playSoundToggled(Bool)
  case onStartPeriodToggled(Bool)
  case onStartBreakToggled(Bool)
  case onLongPauseToggled(Bool)
  case onHalfwayToDailyToggled(Bool)
  case onReachingDailyTargetToggled(Bool)
}

public final class NotificationSettingsEditor: Form<NotificationSettingsEditorState> {
  var userAction: (NotificationSettingsEditorAction) -> Void

  public init(userData: AnyPublisher<NotificationSettingsEditorState, Never>,
              userAction: @escaping (NotificationSettingsEditorAction) -> Void)
  {
    self.userAction = userAction

    super.init(userData: userData) { publisher, currentValue in
      Section(header: "Status") {
        ToggleRow(title: "Show Notifications",
                  isOn: publisher.map(\.showNotifications).eraseToAnyPublisher())
        { userAction(.showNotificationsToggled($0)) }

        if currentValue.showNotifications {
          ToggleRow(title: "Play Sounds",
                    isOn: publisher.map(\.playSound).eraseToAnyPublisher())
          { userAction(.playSoundToggled($0)) }
        }
      }

      if currentValue.showNotifications {
        Section(header: "Transitioning") {
          Toggle(title: "Ready to start work", isOn: publisher.map(\.onStartPeriod).eraseToAnyPublisher())
            { userAction(.onStartPeriodToggled($0)) }

          Toggle(title: "Ready for a break", isOn: publisher.map(\.onStartBreak).eraseToAnyPublisher())
            { userAction(.onStartBreakToggled($0)) }
        }

        Section(header: "Inactivity Reminder", footer: "Shows an alert if countdown paused for too long.") {
          Toggle(title: "Long Pauses", isOn: publisher.map(\.onLongPause).eraseToAnyPublisher())
            { userAction(.onLongPauseToggled($0)) }
        }

        Section(header: "Significant Progress") {
          Toggle(title: "Halfway", isOn: publisher.map(\.onHalfwayToDailyTarget).eraseToAnyPublisher())
            { userAction(.onHalfwayToDailyToggled($0)) }

          Toggle(title: "Target Reached", isOn: publisher.map(\.onReachingDailyTarget).eraseToAnyPublisher())
            { userAction(.onReachingDailyTargetToggled($0)) }
        }
      }
    }
  }
}
