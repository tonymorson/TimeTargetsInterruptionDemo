import Foundation

// UserActivity holds a timeline references and an entry comment?

// Entries might include: Started?  Stopped? Reset? Jump to Next?  (we already know of course but we might want to enforce excuse types...)

// Maybe each timeline can have interruption associated or we just have remarks

// public struct UserActivity: Equatable, Codable {
//  public init(action: TimelineAction, timeline: Timeline) {
//    self.action = action
//    self.timeline = timeline
//  }
//
//  public var action: TimelineAction
//  public var timeline: Timeline
// }

public extension TimelineAction {
  var logName: String {
    switch self {
    case .pause:
      return "Paused countdown"
    case .restartCurrentPeriod:
      return "Restarted period"
    case .resetTimelineToTickZero:
      return "Reset schedule"
    case .resume:
      return "Resumed countdown"
    case .skipCurrentPeriod:
      return "Skipped period"
    case .changedTimeline:
      return "Changed settings"
    }
  }
}

public func userActivitesReducer(state: inout UserActivitesState, action: TimelineAction) {
  switch action {
 
  case .pause:
    var timeline = state.latestTimeline
    timeline.pauseCountdown(at: Date.init)
    state.updateCurrentTick(for: Date.init)
    state.history.append(UserActivity(action: .pause, timeline: timeline))
    
  case .resume:
    var timeline = state.latestTimeline
    timeline.resumeCountdown(from: Date.init)
    state.updateCurrentTick(for: Date.init)
    state.history.append(UserActivity(action: .resume, timeline: timeline))

  case .restartCurrentPeriod:
    var timeline = state.latestTimeline
    timeline.moveCountdownToStartOfCurrentPeriod(at: Date.init)
    timeline.resumeCountdown(from: Date.init)
    state.history.append(UserActivity(action: .restartCurrentPeriod, timeline: timeline))
    state.updateCurrentTick(for: Date.init)

  case .skipCurrentPeriod:
    var timeline = state.latestTimeline
    timeline.moveCountdownToStartOfNextPeriod(at: Date.init)
    timeline.resumeCountdown(from: Date.init)
    state.history.append(UserActivity(action: .skipCurrentPeriod, timeline: timeline))
    state.updateCurrentTick(for: Date.init)

  case .resetTimelineToTickZero:
    var timeline = state.latestTimeline
    timeline.resetCountdownToTickZero(date: Date.init)
    state.history.append(UserActivity(action: .resetTimelineToTickZero, timeline: timeline))
    state.updateCurrentTick(for: Date.init)

  case .changedTimeline:
    break
  }
}
