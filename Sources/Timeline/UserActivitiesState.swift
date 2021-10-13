import Foundation

public struct UserActivitesState: Equatable, Codable {
  public init(history: [UserActivity], currentTick: Int = 0) {
    self.currentTick = currentTick
    self.history = history
  }

  public var currentTick: Int
  public var history: [UserActivity]

  public var latestTimeline: Timeline {
    history.last?.timeline ?? Timeline()
  }

  public var isCountingDown: Bool {
    latestTimeline.countdown.isCountingDown(at: currentTick)
  }

  public var isPaused: Bool {
    !isCountingDown
  }

  public mutating func updateCurrentTick(for date: () -> Date) {
    guard let activity = history.last else { currentTick = 0; return }
    currentTick = activity.timeline.countdown.tick(at: date())
  }
}

public struct UserActivity: Equatable, Codable {
  public init(action: TimelineAction, timeline: Timeline) {
    self.action = action
    self.timeline = timeline
  }

  public var action: TimelineAction
  public var timeline: Timeline
}
