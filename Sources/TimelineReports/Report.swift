import Durations
import Foundation
import Periods
import Ticks
import Timeline

public struct Report: Codable, Equatable {
  public let timeline: Timeline
  public var tick: Tick

  public let currentPeriod: Period
  public let nextPeriod: Period?

  public let periodTicksRemaining: TickCount
  public let periodProgress: Double
  public let periodDuration: Duration

  public let session: [Period]
  public let sessionIdx: Int
  public let sessionWorkPeriodsVisitedCount: TickCount
  public let numWorkPeriodsInSession: Int
  public let sessionProgress: Double
  public let sessionDuration: Duration

  public let targetTickRange: Ticks
  public let targetProgress: Double
  public let targetDuration: Duration

  public let usedWorkTicksCount: TickCount
  public let unusedWorkTicksCount: TickCount

  public let isCountingDown: Bool

  public init(timeline: Timeline, tick: Tick) {
    self.timeline = timeline
    self.tick = tick

    let workPattern = timeline.periods
    let dailyTarget = timeline.dailyTarget

    isCountingDown = timeline.countdown.isCountingDown(at: tick)

    currentPeriod = workPattern.periodAt(tick)
    nextPeriod = workPattern.nextPeriodAt(tick)

    periodTicksRemaining = min(max(0, currentPeriod.tickRange.upperBound - tick), currentPeriod.tickRange.count)
    periodProgress = currentPeriod.tickRange.progress(at: tick)
    periodDuration = currentPeriod.tickRange.duration

    (session, sessionIdx) = workPattern.sessionAt(tick)

    sessionWorkPeriodsVisitedCount = session.workPeriodsVisited(at: tick).count

    numWorkPeriodsInSession = session.filter(\.isWorkPeriod).count
    sessionProgress = session.workProgress(at: tick)
    sessionDuration = session.map(\.tickRange).flatten.duration

    targetTickRange = 0 ... max(0, workPattern.nthWorkPeriod(dailyTarget).tickRange.upperBound)
    targetProgress = workPattern.targetProgressAt(tick, dailyTarget)
    targetDuration = workPattern.targetTick(at: 0, workPeriodsPerDay: dailyTarget).seconds

    let currentPeriodIndex = workPattern.indexOfPeriodAt(tick) / 2
    usedWorkTicksCount = TickCount(workPattern.work.converted(to: .seconds).value) *
      (currentPeriodIndex + 1) - (currentPeriod.isWorkPeriod ? periodTicksRemaining : 0)

    let numWorkTicks = TickCount(workPattern.work.converted(to: .seconds).value) * dailyTarget

    unusedWorkTicksCount = numWorkTicks - usedWorkTicksCount
  }

//  public init(workPattern: WorkPattern, dailyTarget: Int, tick: Tick, isCountingDown: Bool) {
//
//    let tick = max(0, tick)
//    self.isCountingDown = isCountingDown
//
//    self.tick = tick
//
//    currentPeriod = workPattern.periodAt(tick)
//    nextPeriod = workPattern.nextPeriodAt(tick)
//
//    periodTicksRemaining = min(max(0, currentPeriod.tickRange.upperBound - tick), currentPeriod.tickRange.count)
//    periodProgress = currentPeriod.tickRange.progress(at: tick)
//    periodDuration = currentPeriod.tickRange.duration
//
//    (session, sessionIdx) = workPattern.sessionAt(tick)
//
//    sessionWorkPeriodsVisitedCount = session.workPeriodsVisited(at: tick).count
//
//    numWorkPeriodsInSession = session.filter(\.isWorkPeriod).count
//    sessionProgress = session.workProgress(at: tick)
//    sessionDuration = session.map(\.tickRange).flatten.duration
//
//    targetTickRange = 0 ... max(0, workPattern.nthWorkPeriod(dailyTarget).tickRange.upperBound)
//    targetProgress = workPattern.targetProgressAt(tick, dailyTarget)
//    targetDuration = workPattern.targetTick(at: 0, workPeriodsPerDay: dailyTarget).seconds
//
//    let currentPeriodIndex = workPattern.indexOfPeriodAt(tick) / 2
//    usedWorkTicksCount = TickCount(workPattern.work.converted(to: .seconds).value) *
//      (currentPeriodIndex + 1) - (currentPeriod.isWorkPeriod ? periodTicksRemaining : 0)
//
//    let numWorkTicks = TickCount(workPattern.work.converted(to: .seconds).value) * dailyTarget
//
//    unusedWorkTicksCount = numWorkTicks - usedWorkTicksCount
//  }

//  public init(periods: [(Period.Kind, Duration)], dailyTarget: Int, tick: Tick, isCountingDown: Bool) {
//    let tick = max(0, tick)
//
//    let periods = periods
//      .map { ($0.0, 0 ... Tick($0.1.asSeconds)) }
//      .map(Period.init)
//      .resequenced()
//
//    self.init(periods: periods, dailyTarget: dailyTarget, tick: tick, isCountingDown: isCountingDown)
//  }

//  private init(periods: [Period], dailyTarget: Int, tick: Tick, isCountingDown: Bool) {
//    let tick = max(0, tick)
//
//    self.tick = tick
//    self.isCountingDown = isCountingDown
//
//    let emptyPeriod = Period(kind: .work, tickRange: 0 ... 0)
//
//    currentPeriod = periods.periodAt(tick: tick) ?? periods.last ?? emptyPeriod
//    nextPeriod = periods.periodAfterPeriodAt(tick: tick)
//
//    periodTicksRemaining = min(max(0, currentPeriod.tickRange.upperBound - tick), currentPeriod.tickRange.count)
//    periodProgress = currentPeriod.tickRange.progress(at: tick)
//    periodDuration = currentPeriod.tickRange.duration
//
//    (session, sessionIdx) = (periods, 0)
//    sessionWorkPeriodsVisitedCount = session.workPeriodsVisited(at: tick).count
//
//    numWorkPeriodsInSession = session.filter(\.isWorkPeriod).count
//    sessionProgress = session.workProgress(at: tick)
//    sessionDuration = session.map(\.tickRange).flatten.duration
//
//    let workPeriods = periods
//      .workPeriods
//      .prefix(dailyTarget)
//
//    targetTickRange = 0 ... (workPeriods.last?.tickRange.upperBound ?? 0)
//    targetDuration = workPeriods.last?.tickRange.upperBound.seconds ?? 0.seconds
//
//    usedWorkTicksCount = workPeriods.numberOfTicksConsumed(at: tick)
//
//    unusedWorkTicksCount = workPeriods.numberOfTicksRemaining(at: tick)
//
//    targetProgress = sessionProgress
//  }

//  public init(sessions: [[(Period.Kind, Duration)]], dailyTarget: Int, tick: Tick, isCountingDown: Bool) {
//    self.tick = tick
//    self.isCountingDown = isCountingDown
//
//    let emptyPeriod = Period(kind: .work, tickRange: 0 ... 0)
//
//    let sessions = sessions.map {
//      $0
//        .map { ($0.0, 0 ... Tick($0.1.asSeconds)) }
//        .map(Period.init)
//    }
//    .resequenced()
//
//    let periods = sessions
//      .flatMap { $0 }
//
//    currentPeriod = periods.periodAt(tick: tick) ?? periods.last ?? emptyPeriod
//    nextPeriod = periods.periodAfterPeriodAt(tick: tick)
//
//    periodTicksRemaining = min(max(0, currentPeriod.tickRange.upperBound - tick), currentPeriod.tickRange.count)
//    periodProgress = currentPeriod.tickRange.progress(at: tick)
//    periodDuration = currentPeriod.tickRange.duration
//
//    if let sessionPeriods = sessions.first(where: { $0.map(\.tickRange).contains(tick: tick) }),
//       let sessionIndex = sessions.firstIndex(of: sessionPeriods)
//    {
//      (session, sessionIdx) = (sessionPeriods, sessionIndex)
//    } else {
//      session = []
//      sessionIdx = 0
//    }
//
//    sessionWorkPeriodsVisitedCount = session.workPeriodsVisited(at: tick).count
//
//    numWorkPeriodsInSession = session.filter(\.isWorkPeriod).count
//    sessionProgress = session.workProgress(at: tick)
//    sessionDuration = session.map(\.tickRange).flatten.duration
//
//    let workPeriods = periods
//      .workPeriods
//      .prefix(dailyTarget)
//
//    targetTickRange = 0 ... (workPeriods.last?.tickRange.upperBound ?? 0)
//    targetDuration = workPeriods.last?.tickRange.upperBound.seconds ?? 0.seconds
//
//    usedWorkTicksCount = workPeriods.numberOfTicksConsumed(at: tick)
//
//    unusedWorkTicksCount = workPeriods.numberOfTicksRemaining(at: tick)
//
//    targetProgress = periods.workProgress(at: tick)
//  }
}

private extension Array where Element == Ticks {
  var flatten: Ticks {
    guard !isEmpty else { return 0 ... 0 }
    return (first!.lowerBound ... last!.upperBound)
  }
}

// MARK: - Curried functions for point free mapping

private extension Array where Element == Period {
  var workPeriods: [Period] {
    filter(\.isWorkPeriod)
  }

  func workPeriodsVisited(at tick: Tick) -> [Period] {
    prefix { $0.tickRange.lowerBound <= tick }
      .filter(\.isWorkPeriod)
  }
}

private extension RandomAccessCollection where Element == Period {
  func numberOfTicksConsumed(at tick: Tick) -> TickCount {
    filter(\.isWorkPeriod)
      .map(\.tickRange)
      .map { $0.numberOfTicksConsumed(at: tick) }
      .reduce(0, +)
  }
}

extension RandomAccessCollection where Element == Period {
  func numberOfTicksRemaining(at tick: Tick) -> TickCount {
    filter(\.isWorkPeriod)
      .map(\.tickRange)
      .map { $0.numberOfTicksRemaining(at: tick) }
      .reduce(0, +)
  }
}

private extension Ticks {
  func numberOfTicksConsumed(at tick: Tick) -> TickCount {
    if tick < lowerBound { return 0 }
    if tick > upperBound { return count - 1 }

    return tick - lowerBound
  }
}

private extension Ticks {
  func numberOfTicksRemaining(at tick: Tick) -> TickCount {
    if tick < lowerBound { return count - 1 }
    if tick > upperBound { return 0 }

    return upperBound - tick
  }
}

private extension Array where Element == Ticks {
  func contains(tick: Tick) -> Bool {
    for tickRange in self where tickRange ~= tick {
      return true
    }
    return false
  }
}

extension Ticks {
  var duration: Duration {
    count.seconds - 1.seconds
  }
}

