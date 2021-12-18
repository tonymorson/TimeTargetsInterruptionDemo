import ComposableArchitecture
import Timeline
import TimelineTickEffect

public struct UserActivityState: Equatable {
  public var history: [Timeline]
  public var tick: Tick

  public init(tick: Tick, history: [Timeline]) {
    self.tick = tick
    self.history = history
  }
}

public extension UserActivityState {
  var timeline: Timeline? {
    history.last
  }
}

public enum UserActivityAction: Equatable {
  case pause
  case restartCurrentPeriod
  case resetTimelineToTickZero
  case resume
  case skipCurrentPeriod
  case timerTicked
}

public struct UserActivityEnvironment {
  var date: () -> Date
  var scheduler: AnySchedulerOf<RunLoop>

  public init(date: @escaping () -> Date, scheduler: AnySchedulerOf<RunLoop>) {
    self.date = date
    self.scheduler = scheduler
  }
}

public let UserActivityReducer = Reducer<UserActivityState, UserActivityAction, UserActivityEnvironment> { state, action, environment in
  switch action {
  case .resume:

    var timeline = state.timeline ?? .init()

    if timeline.countdown.isCountingDown(at: state.tick) {
      return .none
    }

    timeline.resumeCountdown(from: environment.date)
    state.history.append(timeline)

    return tickEffect(for: timeline,
                      at: state.tick,
                      on: environment.scheduler)
      .map { _ in .timerTicked }
      .eraseToEffect()

  case .pause:
    var timeline = state.timeline ?? .init()
    timeline.pauseCountdown(at: environment.date)
    state.history.append(timeline)

    return tickEffect(for: timeline,
                      at: state.tick,
                      on: environment.scheduler)
      .map { _ in .timerTicked }
      .eraseToEffect()

  case .restartCurrentPeriod:
    var timeline = state.timeline ?? .init()
    timeline.stopCountdownAtStartOfCurrentPeriod(at: environment.date)
    timeline.resumeCountdown(from: environment.date)
    state.history.append(timeline)
    state.tick = timeline.countdown.tick(at: environment.date())

    return tickEffect(for: timeline,
                      at: state.tick,
                      on: environment.scheduler)
      .map { _ in .timerTicked }
      .eraseToEffect()

  case .resetTimelineToTickZero:
    var timeline = state.timeline ?? .init()
    timeline.pauseCountdown(at: environment.date)
    state.history.append(timeline)
    state.tick = .zero

    return tickEffect(for: timeline,
                      at: state.tick,
                      on: environment.scheduler)
      .map { _ in .timerTicked }
      .eraseToEffect()

  case .skipCurrentPeriod:
    var timeline = state.timeline ?? .init()
    timeline.stopCountdownAtStartOfNextPeriod(at: environment.date)
    state.history.append(timeline)
    state.tick = timeline.countdown.tick(at: environment.date())

    return tickEffect(for: timeline,
                      at: state.tick,
                      on: environment.scheduler)
      .map { _ in .timerTicked }
      .eraseToEffect()

  case .timerTicked:
    assert(!state.history.isEmpty)

    guard let timeline = state.timeline else { return .none }

    state.tick = timeline.countdown.tick(at: environment.date())

    return .none
  }
}
