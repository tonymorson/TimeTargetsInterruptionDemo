import Foundation

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
    case .toggle:
      return "Toggled countdown"
    case .changedTimeline:
      return "Changed settings"
    }
  }
}

public func userActivitesReducer(state: inout UserActivitesState, action: TimelineAction) {
  switch action {
//  case .ticked:
//    state.updateCurrentTick(for: Date.init)
  case .toggle:
    var timeline = state.latestTimeline
    timeline.toggleCountdown(at: Date.init)
    state.updateCurrentTick(for: Date.init)
    state.history.append(UserActivity(action: .toggle, timeline: timeline))
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
  case .pause:
    var timeline = state.latestTimeline
    timeline.pauseCountdown(at: Date.init)
    state.updateCurrentTick(for: Date.init)
    state.history.append(UserActivity(action: .pause, timeline: timeline))
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
  case .resume:
    var timeline = state.latestTimeline
    timeline.resumeCountdown(from: Date.init)
    state.updateCurrentTick(for: Date.init)
    state.history.append(UserActivity(action: .resume, timeline: timeline))
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
  case .restartCurrentPeriod:
    var timeline = state.latestTimeline
    timeline.moveCountdownToStartOfCurrentPeriod(at: Date.init)
    timeline.resumeCountdown(from: Date.init)
    state.history.append(UserActivity(action: .restartCurrentPeriod, timeline: timeline))
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
  case .skipCurrentPeriod:
    var timeline = state.latestTimeline
    timeline.moveCountdownToStartOfNextPeriod(at: Date.init)
    timeline.resumeCountdown(from: Date.init)
    state.history.append(UserActivity(action: .skipCurrentPeriod, timeline: timeline))
    state.updateCurrentTick(for: Date.init)
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
  case .resetTimelineToTickZero:
    var timeline = state.latestTimeline
    timeline.resetCountdownToTickZero(date: Date.init)
    state.history.append(UserActivity(action: .resetTimelineToTickZero, timeline: timeline))
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
  case .changedTimeline:
    break
  }
}

// public let userActivitiesReducer = Reducer<UserActivitesState, UserActivitiesAction> { state, action, environment in
//  switch action {
//  case .ticked:
//    state.updateCurrentTick(for: environment.date)
//  case .timelineChanged(.toggle):
//    var timeline = state.latestTimeline
//    timeline.toggleCountdown(at: environment.date)
//    state.updateCurrentTick(for: environment.date)
//    state.history.append(UserActivity(action: .toggle, timeline: timeline))
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
//  case .timelineChanged(.pause):
//    var timeline = state.latestTimeline
//    timeline.pauseCountdown(at: environment.date)
//    state.updateCurrentTick(for: environment.date)
//    state.history.append(UserActivity(action: .pause, timeline: timeline))
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
//  case .timelineChanged(.resume):
//    var timeline = state.latestTimeline
//    timeline.resumeCountdown(from: environment.date)
//    state.updateCurrentTick(for: environment.date)
//    state.history.append(UserActivity(action: .resume, timeline: timeline))
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
//  case .timelineChanged(.restartCurrentPeriod):
//    var timeline = state.latestTimeline
//    timeline.moveCountdownToStartOfCurrentPeriod(at: environment.date)
//    timeline.resumeCountdown(from: environment.date)
//    state.history.append(UserActivity(action: .restartCurrentPeriod, timeline: timeline))
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
//  case .timelineChanged(.skipCurrentPeriod):
//    var timeline = state.latestTimeline
//    timeline.moveCountdownToStartOfNextPeriod(at: environment.date)
//    timeline.resumeCountdown(from: environment.date)
//    state.history.append(UserActivity(action: .skipCurrentPeriod, timeline: timeline))
//    state.updateCurrentTick(for: environment.date)
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
//  case .timelineChanged(.resetTimelineToTickZero):
//    var timeline = state.latestTimeline
//    timeline.resetCountdownToTickZero(date: environment.date)
//    state.history.append(UserActivity(action: .resetTimelineToTickZero, timeline: timeline))
//    return state.liveTimeline.timerEffect(scheduler: environment.tickScheduler)
//  case .timelineChanged(.changedTimeline):
//    break
//  }
//
//  return .none
// }
