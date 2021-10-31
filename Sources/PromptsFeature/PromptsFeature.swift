import ComposableArchitecture
import Foundation
import Ticks
import Timeline
import TimelineTickEffect

public struct PromptsState: Equatable {
  var tick: Tick
  var timeline: Timeline
  var interruption: Interruption?

  public init() {
    tick = .zero
    timeline = .init()
  }

  var isTimelineInterrupted: Bool {
    if timeline.countdown.isCountingDown(at: tick) {
      return false
    }

    if timeline.periods.periodAt(tick).firstTick == tick {
      return false
    }

    return true
  }
}

public enum PromptsAction: Equatable {
  case interruptionTapped(Interruption)
  case timeline(TimelineAction)
  case timerTicked
}

public struct PromptsEnv {
  var date: () -> Date

  public init(date: @escaping () -> Date) {
    self.date = date
  }
}

public let promptsReducer = Reducer<PromptsState, PromptsAction, PromptsEnv> { state, action, env in
  switch action {
  case .timeline(let action):

    state.interruption = nil

    switch action {
    case .pause:
      var timeline = state.timeline
      timeline.pauseCountdown(at: env.date)
      state.timeline = timeline
      state.tick = state.timeline.countdown.tick(at: env.date())

    case .restartCurrentPeriod:
      var timeline = state.timeline
      timeline.moveCountdownToStartOfCurrentPeriod(at: env.date)
      state.timeline = timeline
      state.tick = state.timeline.countdown.tick(at: env.date())

    case .resetTimelineToTickZero:
      var timeline = state.timeline
      timeline.pauseCountdown(at: env.date)
      state.timeline = timeline
      state.tick = .zero

    case .resume:
      var timeline = state.timeline
      timeline.resumeCountdown(from: env.date)
      state.timeline = timeline
      state.tick = state.timeline.countdown.tick(at: env.date())

    case .skipCurrentPeriod:
      var timeline = state.timeline
      timeline.moveCountdownToStartOfNextPeriod(at: env.date)
      state.timeline = timeline
      state.tick = state.timeline.countdown.tick(at: env.date())

    case .changedTimeline:
      break
    }

    return tickEffect(for: state.timeline, at: state.tick, on: .main)
      .map { _ in .timerTicked }
      .eraseToEffect()

  case .timerTicked:
    state.tick = state.timeline.countdown.tick(at: env.date())

    return .none

  case .interruptionTapped(let interruption):
    state.interruption = interruption

    return .none
  }
}

extension PromptsState {
  var prompts: (String, String) {
    // Create placeholder fields to be filled in and returned later
    let title: String
    let subtitle: String

    // Get the stance of the current moment on the timeline
    let stance = timeline.stance(at: tick)

    // Depending on the stance, fill out the prompt fields accordingly
    switch stance {
    case .paused(.restingAtTickZero):
      title = "Ready to start?"
      subtitle = "You have 10 work periods remaining."

    case .paused(.restingAtStartOfWorkPeriod):
      title = "Ready to start another work period?"
      subtitle = "You have x work periods remaining." // FIXME:

    case .paused(.restingAtStartOfBreak):
      title = "Ready to take a break?"
      subtitle = "You have worked x hours with y breaks so far." // FIXME:

    case .paused(.reachedTarget):
      title = "Congratulations! Daily work target reached."
      subtitle = ""

    case .paused(.interrupted):
      title = interruptionDescription
      subtitle = "This is your 5th interruption this period." // FIXME:

    case .running(.inLastPhaseOfWorkPeriod):
      title = "Prepare to wind down work period soon."
      subtitle = "Next break at \(nextPeriodETADesc)."

    case .running(.inLastPhaseOfBreakPeriod):
      title = "Break ends soon."
      subtitle = "Next work period at \(nextPeriodETADesc)."

    case .running(.resumedBreakPeriod):
      title = "Resumed break!"
      subtitle = "Next work period at \(nextPeriodETADesc)."

    case .running(.resumedWorkPeriod):
      title = "Resumed work period!"
      subtitle = "Next break at \(nextPeriodETADesc)."

    case .running(.transitioningToNextBreakPeriod):
      title = "Time for a break!"
      subtitle = "Next work period at \(nextPeriodETADesc)."

    case .running(.transitioningToNextWorkPeriod):
      title = "Time to start work!"
      subtitle = "Next break at \(nextPeriodETADesc)."

    case .running(.fromStartOfBreakPeriod):
      title = "Started Break."
      subtitle = "Next work period at \(nextPeriodETADesc)."

    case .running(.fromStartOfWorkPeriod):
      title = "Started work period."
      subtitle = "Next break at \(nextPeriodETADesc)."

    case .running(.bodyOfWorkPeriod):
      title = ""
      subtitle = "Next break at \(nextPeriodETADesc)."

    case .running(.bodyOfBreakPeriod):
      title = ""
      subtitle = "Next work period at \(nextPeriodETADesc)."
    }

    // Return the filled-in prompts
    return (title, subtitle)
  }
}

extension PromptsState {
  var interruptionDescription: String {
    let interruptionTime = timeline.countdown.time(at: tick)
    let timeDescription = interruptionTime.formatted(date: .omitted, time: .shortened)

    guard let interruption = interruption else {
      return "Countdown paused at \(timeDescription)."
    }

    return "\(interruption.excuse) at \(timeDescription)"
  }

  var timelineActionMenuItems: [PromptsView.ViewAction.TimelineAction] {
    let isCountingDown = timeline.countdown.isCountingDown(at: tick)
    let currentPeriod = timeline.periods.periodAt(tick)
    let isWorkTime = currentPeriod.isWorkPeriod
    let isAtStartOfPeriod = currentPeriod.firstTick == tick

    switch (isCountingDown, isWorkTime, isAtStartOfPeriod) {
    case (true, true, true):
      return [.pauseWorkPeriod, .skipToNextBreak]

    case (true, true, false):
      return [.pauseWorkPeriod, .skipToNextBreak, .restartWorkPeriod]

    case (true, false, true):
      return [.pauseBreak, .skipToNextWorkPeriod]

    case (true, false, false):
      return [.pauseBreak, .skipToNextWorkPeriod, .restartBreak]

    case (false, true, true):
      return [.startWorkPeriod, .skipToNextBreak]

    case (false, true, false):
      return [.resumeWorkPeriod, .skipToNextBreak, .restartWorkPeriod]

    case (false, false, true):
      return [.startBreak, .skipToNextWorkPeriod]

    case (false, false, false):
      return [.resumeBreak, .skipToNextWorkPeriod, .restartBreak]
    }
  }

  var nextPeriodETA: Date {
    let nextPeriod = timeline.periods.nextPeriodAt(tick)

    return timeline.countdown.time(at: nextPeriod.tickRange.lowerBound)
  }

  var nextPeriodETADesc: String {
    nextPeriodETA.formatted(date: .omitted, time: .shortened)
  }
}

extension PromptsView.ViewAction.TimelineAction {
  var menuTitle: String {
    switch self {
    case .startSchedule: return "Start Schedule"
    case .startBreak: return "Start Break"
    case .startWorkPeriod: return "Start Work Period"
    case .pauseWorkPeriod: return "Pause Work Period"
    case .skipToNextBreak: return "Skip To Next Break"
    case .skipToNextWorkPeriod: return "Skip Break"
    case .restartBreak: return "Restart Break"
    case .restartWorkPeriod: return "Restart Work Period"
    case .pauseBreak: return "Pause Break"
    case .resumeBreak: return "Resume Break"
    case .resumeWorkPeriod: return "Resume Work Period"
    }
  }

  var menuImageName: String? {
    switch self {
    case .startSchedule: return "arrow.right"
    case .startBreak: return "arrow.right"
    case .startWorkPeriod: return "arrow.right"
    case .pauseWorkPeriod: return "pause"
    case .skipToNextBreak: return "arrow.right.to.line"
    case .skipToNextWorkPeriod: return "arrow.right.to.line"
    case .restartBreak: return "arrow.left.to.line"
    case .restartWorkPeriod: return "arrow.left.to.line"
    case .pauseBreak: return "pause"
    case .resumeBreak: return "arrow.right"
    case .resumeWorkPeriod: return "arrow.right"
    }
  }
}

extension PromptsAction {
  init(action: PromptsView.ViewAction) {
    switch action {
    case .timeline(.startSchedule):
      self = .timeline(.resume)
    case .timeline(.startWorkPeriod):
      self = .timeline(.resume)
    case .timeline(.startBreak):
      self = .timeline(.resume)
    case .timeline(.resumeBreak):
      self = .timeline(.resume)
    case .timeline(.resumeWorkPeriod):
      self = .timeline(.resume)

    case .timeline(.pauseBreak):
      self = .timeline(.pause)
    case .timeline(.pauseWorkPeriod):
      self = .timeline(.pause)

    case .timeline(.skipToNextBreak):
      self = .timeline(.skipCurrentPeriod)
    case .timeline(.skipToNextWorkPeriod):
      self = .timeline(.skipCurrentPeriod)

    case .timeline(.restartBreak):
      self = .timeline(.restartCurrentPeriod)
    case .timeline(.restartWorkPeriod):
      self = .timeline(.restartCurrentPeriod)

    case .interruptionTapped(let interruption):
      self = .interruptionTapped(interruption)
    }
  }
}

extension PromptsState {
  var timelineActions: [PromptsView.ViewAction.TimelineAction] {
    let isCountingDown = timeline.countdown.isCountingDown(at: tick)
    let currentPeriod = timeline.periods.periodAt(tick)
    let isWorkTime = currentPeriod.isWorkPeriod
    let isAtStartOfPeriod = currentPeriod.firstTick == tick

    switch (isCountingDown, isWorkTime, isAtStartOfPeriod) {
    case (true, true, true):
      return [.pauseWorkPeriod, .skipToNextBreak]

    case (true, true, false):
      return [.pauseWorkPeriod, .skipToNextBreak, .restartWorkPeriod]

    case (true, false, true):
      return [.pauseBreak, .skipToNextWorkPeriod]

    case (true, false, false):
      return [.pauseBreak, .skipToNextWorkPeriod, .restartBreak]

    case (false, true, true):
      return [.startWorkPeriod, .skipToNextBreak]

    case (false, true, false):
      return [.resumeWorkPeriod, .skipToNextBreak, .restartWorkPeriod]

    case (false, false, true):
      return [.startBreak, .skipToNextWorkPeriod]

    case (false, false, false):
      return [.resumeBreak, .skipToNextWorkPeriod, .restartBreak]
    }
  }
}

extension Timeline {
  enum TimelineObservation: Equatable {
    enum pausedObservation {
      case restingAtTickZero
      case restingAtStartOfWorkPeriod
      case restingAtStartOfBreak
      case interrupted
      case reachedTarget
    }

    enum runningObservation {
      case resumedWorkPeriod
      case resumedBreakPeriod
      case fromStartOfWorkPeriod
      case fromStartOfBreakPeriod
      case transitioningToNextWorkPeriod
      case transitioningToNextBreakPeriod
      case inLastPhaseOfWorkPeriod
      case inLastPhaseOfBreakPeriod
      case bodyOfWorkPeriod
      case bodyOfBreakPeriod
    }

    case paused(pausedObservation)
    case running(runningObservation)
  }

  func stance(at tick: Int) -> TimelineObservation {
    let isCountingDown = countdown.isCountingDown(at: tick)
    let isPaused = !isCountingDown

    if isPaused, tick == 0 {
      return .paused(.restingAtTickZero)
    }

    let currentPeriod = periods.periodAt(tick)

    if isPaused, currentPeriod.firstTick == tick, currentPeriod.isWorkPeriod {
      return .paused(.restingAtStartOfWorkPeriod)
    }

    if isPaused, currentPeriod.firstTick == tick, !currentPeriod.isWorkPeriod {
      return .paused(.restingAtStartOfBreak)
    }

    if isPaused {
      return .paused(.interrupted)
    }

    if isCountingDown,
       countdown.startTick == currentPeriod.firstTick,
       tick <= (currentPeriod.firstTick + 3)
    {
      return currentPeriod.isWorkPeriod
        ? .running(.fromStartOfWorkPeriod)
        : .running(.fromStartOfBreakPeriod)
    }

    if isCountingDown,
       currentPeriod != periods.periodAt(countdown.startTick),
       tick >= currentPeriod.firstTick,
       tick <= (currentPeriod.firstTick + 3)
    {
      return currentPeriod.isWorkPeriod
        ? .running(.transitioningToNextWorkPeriod)
        : .running(.transitioningToNextBreakPeriod)
    }

    if isCountingDown,
       currentPeriod.isWorkPeriod,
       countdown.startTick >= countdown.ticks.lowerBound,
       tick <= countdown.ticks.lowerBound + 3
    {
      return .running(.resumedWorkPeriod)
    }

    if isCountingDown,
       tick >= currentPeriod.lastTick - 10,
       tick <= currentPeriod.lastTick - 10 + 3
    {
      return .running(.inLastPhaseOfWorkPeriod)
    }

    return currentPeriod.isWorkPeriod
      ? .running(.bodyOfWorkPeriod)
      : .running(.bodyOfBreakPeriod)
  }
}
