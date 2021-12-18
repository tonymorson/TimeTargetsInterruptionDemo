import Foundation
import Timeline
import UserNotifications

let firstReminderTimeInterval = 2.0 * 60
let secondReminderTimeInterval = 5.0 * 60
let finalReminderTimeInterval = 10.0 * 60

public actor NotificationsFactory {
  public init() {}

  public func makeCountingDownNotifications(for timeline: Timeline, at tick: Tick) -> [UNNotificationRequest] {
    let liveTimeline = LiveTimeline(timeline: timeline, currentTick: tick)

    var requests = liveTimeline.makeCountingDownNotifications()
    requests.append(contentsOf: liveTimeline.makeCountdownPausedSignificantlyNotifications())

    return requests
  }
}

private extension LiveTimeline {
//  func makeCountingDownNotifications(options: NotificationsSettingsState) -> [UNNotificationRequest] {
  func makeCountingDownNotifications() -> [UNNotificationRequest] {
//    makeInFlightNotifications(options: options)
    timeline.makeInFlightNotifications()
      .filter { $0.fire > 0 }
//      .filter(meetsUserRequirements(for: options))
      .map { ($0, true) }
      .map(UNNotificationRequest.init)
  }

  func makeCountdownPausedSignificantlyNotifications() -> [UNNotificationRequest] {
//  func makeCountdownPausedSignificantlyNotifications(options: NotificationsSettingsState) -> [UNNotificationRequest] {
    makePausedReminders()
//    makePausedReminders(options: options)
      .filter { $0.fire > 0 }
      .map { ($0, true) }
      .map(UNNotificationRequest.init)
  }

//  func makeMilestoneNotifications(options: NotificationsSettingsState) -> [UNNotificationRequest] {
//    guard isCountingDown, options.showSignificantProgressAlerts else { return [] }
//
//    let milestone = setCurrentTick(to: nextHalfwayTargetTickAfter(tick: currentTick))
//    guard !milestone.isAtStartOfPeriod else { return [] }
//
//    let content = UNMutableNotificationContent()
//    content.title = "You have reached \(milestone.describeProgress) of your goal ✊"
//    content.categoryIdentifier = "RichNotifications"
//    content.sound = options.playAlertSound ? .default : nil
  ////    content.summaryArgument = "this work sprint."
//
//    let fire = timeIntervalTo(milestone)
//    guard fire > 0 else { return [] }
//
//    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fire, repeats: false)
//
//    return [
//      UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger),
//    ]
//  }
}

extension LiveTimeline {
  func makePausedReminders() -> [NotificationDescriptor] {
    let nextTargetTick = timeline.periods.targetTick(at: currentTick, workPeriodsPerDay: timeline.dailyTarget) + 1
//  func makePausedReminders(options: NotificationsSettingsState) -> [NotificationDescriptor] {
    guard !isWaitingAtScheduleStart
    else { return [] }

    guard timeline.countdown.stopTick != nextTargetTick
    else { return [] }

    return [
      .init(
        timeline: timeline,
        tick: timeline.countdown.stopTick + Int(firstReminderTimeInterval)
//        shouldPlaySound: true// options.playAlertSound
      ),

      .init(
        timeline: timeline,
        tick: timeline.countdown.stopTick + Int(secondReminderTimeInterval)
//        shouldPlaySound: true// options.playAlertSound
      ),

      .init(
        timeline: timeline,
        tick: timeline.countdown.stopTick + Int(finalReminderTimeInterval)
//        shouldPlaySound: true// options.playAlertSound
      ),
    ]
  }
}

extension Timeline {
//  func makeInFlightNotifications(options: NotificationsSettingsState) -> [NotificationDescriptor] {
  func makeInFlightNotifications() -> [NotificationDescriptor] {
    transitioningTicks
//      .map(setCurrentTick(to:))
//        .map { (self, $0, options) }
      .map { (self, $0) }
      .map(NotificationDescriptor.init)
  }

  var transitioningTicks: Set<Tick> {
    Set(
      periods
        .periods(from: countdown.startTick, to: countdown.stopTick)
        .dropFirst()
        .map(\.tickRange.lowerBound)
    )
  }
}

// func meetsUserRequirements(for options: NotificationsSettingsState)
//  -> (NotificationDescriptor) -> Bool
// { { notification in
//  meetsUserRequirements(notification: notification, options: options)
// }}
//
// func meetsUserRequirements(notification: NotificationDescriptor,
//                           options: NotificationsSettingsState) -> Bool
// {
//  let timeline = notification.timeline
//
//  if timeline.primaryObservation == .readyToStartWork,
//     options.showReadyToStartNextWorkPeriodAlerts
//  {
//    return true
//  }
//
//  if timeline.primaryObservation == .readyToStartShortBreak ||
//    timeline.primaryObservation == .readyToStartLongBreak,
//    options.showReadyToStartNextBreakAlerts
//  {
//    return true
//  }
//
//  if timeline.primaryObservation == .timeForWork,
//     options.showTimeToStartWorkAlerts
//  {
//    return true
//  }
//
//  if timeline.primaryObservation == .timeForAShortBreak ||
//    timeline.primaryObservation == .timeForALongBreak,
//    options.showTimeToTakeABreakAlerts
//  {
//    return true
//  }
//
//  if timeline.primaryObservation == .reachedInitialTarget ||
//    timeline.primaryObservation == .reachedInitialTargetMultiple ||
//    timeline.primaryObservation == .reachedSignificantProgress,
//    options.showSignificantProgressAlerts
//  {
//    return true
//  }
//
//  return false
// }
//
struct NotificationDescriptor {
  var timeline: Timeline
  var tick: Tick
//  var shouldPlaySound: Bool

  var fire: TimeInterval {
    timeline.countdown.startTime.timeIntervalSince(Date()).advanced(by: Double(tick - timeline.countdown.startTick))
  }

  var title: String {
    let timeline = LiveTimeline(timeline: timeline, currentTick: tick)
    if timeline.tertiaryObservation == .fallingBehind {
      return timeline.describePrimaryObservation
    }

    return timeline.isAtStartOfPeriod ? timeline.describePrimaryObservation : ""
  }

  var subtitle: String {
    let timeline = LiveTimeline(timeline: timeline, currentTick: tick)
    if timeline.tertiaryObservation == .fallingBehind {
      return timeline.describeSecondaryObservation
    }

    return timeline.isAtStartOfPeriod ? timeline.describeSecondaryObservation : ""
  }

  var body: String {
    let timeline = LiveTimeline(timeline: timeline, currentTick: tick)
    if timeline.tertiaryObservation == .fallingBehind {
      return timeline.describeTertiaryObservation
    }

    return timeline.describeTertiaryObservation
  }

  var shouldShowInForeground: Bool {
    true
  }

  init(
    timeline: Timeline,
    tick: Tick
//    shouldPlaySound: Bool
  ) {
    self.timeline = timeline
    self.tick = tick
//    self.shouldPlaySound = shouldPlaySound
  }
}

//
// private extension NotificationDescriptor {
//  init(timeline: LiveTimeline, settings: NotificationsSettingsState) {
//    let userInfo: [AnyHashable: Any] = [
//      //          "foreground": Self.shouldDisplayNotificationWhenAppInForeground(markedTimeline),
//      "foreground": true,
//    ]
//
//    self.init(
//      timeline: timeline,
//      tick: timeline.currentTick,
//      shouldPlaySound: settings.playAlertSound
//    )
//  }
// }
//
extension UNNotificationRequest {
  convenience init(notification: NotificationDescriptor, shouldPlaySound: Bool) {
    let identifier = UUID().uuidString

    let content = UNMutableNotificationContent()
    content.body = notification.body
    content.categoryIdentifier = "RichNotifications"
    content.sound = shouldPlaySound ? .default : nil
    content.subtitle = notification.subtitle
//    content.summaryArgument = "this work sprint."
    content.title = notification.title
    //    content.userInfo = notification.userInfo

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: notification.fire, repeats: false)

    self.init(identifier: identifier, content: content, trigger: trigger)
  }
}

//
// extension LiveTimeline {
//  func timeIntervalTo(_ other: LiveTimeline) -> Double {
//    Double(other.currentTick - currentTick)
//  }
// }
