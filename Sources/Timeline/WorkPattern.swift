import Durations
import Foundation
import Periods
import Ticks

public typealias SessionID = Int

public struct WorkPattern: Equatable, Codable {
  public var work: Duration
  public var shortBreak: Duration
  public var longBreak: Duration
  public var numWorkPeriods: Int

  public init(work: Duration, shortBreak: Duration, longBreak: Duration, repeating: Int) {
    self.work = work
    self.shortBreak = shortBreak
    self.longBreak = longBreak
    numWorkPeriods = Int(max(0, repeating) + 1)
  }
}

public extension WorkPattern {
  static var standard: WorkPattern {
    .init(work: 25.seconds, shortBreak: 5.seconds, longBreak: 15.seconds, repeating: 3)
  }
}

public extension WorkPattern {
  var sessionTickCount: TickCount {
    max(0, numWorkPeriods) * work.tickCount
      + max(0, numWorkPeriods - 1) * shortBreak.tickCount
      + longBreak.tickCount
  }

  func sessionPeriodsFor(tick _: Tick) -> [Period] {
    let initial = zip([.work, .shortBreak], [work, shortBreak].map(\.tickRange))
      .map(Period.init)

    let final = zip([.work, .longBreak], [work, longBreak].map(\.tickRange))
      .map(Period.init)

    let sessionPeriods = Array((Array(repeating: initial, count: numWorkPeriods - 1)
        + [final]).joined())

    return sessionPeriods
  }

  func sessionAt(_ tick: Tick) -> (periods: [Period], idx: SessionID) {
    let sessionPeriods = sessionPeriodsFor(tick: tick)
    let idx = sessionIndexAt(tick: tick)

    let amount = sessionTickCount * idx
    let periods = sessionPeriods.resequenced()
      .map(advance(by: amount))

    return (periods, idx)
  }

  func sessionIndexAt(tick: Tick) -> Int {
    tick / sessionTickCount
  }

  func nextPeriodAt(_ tick: Tick) -> Period {
    if let period = sessionAt(tick).periods.periodAfterPeriodAt(tick: tick) {
      return period
    }

    let currentPeriod = periodAt(tick)
    return Period(kind: .work, tickRange: work.tickRange.advanced(by: currentPeriod.tickRange.upperBound + 1))
  }

  func periodAt(_ tick: Tick) -> Period {
    sessionAt(tick)
      .periods
      .periodAt(tick: tick)!
  }

  func nthWorkPeriod(_ idx: Int) -> Period {
    periodAtIdx((abs(idx) * 2) - 2)
  }

  func periodAtIdx(_ idx: Int) -> Period {
    let session = sessionForPeriodAt(idx).periods
    let periodSessionIdx = idx % session.count
    return session[periodSessionIdx]
  }

  func periods(from: Tick, to: Tick) -> [Period] {
    var result = [periodAt(from)]

    while result.last!.tickRange.upperBound < to {
      result.append(periodAt(result.last!.tickRange.upperBound + 1))
    }

    return result
  }

  func sessionForPeriodAt(_ idx: Int) -> (periods: [Period], idx: SessionID) {
    let initialSession = sessionAt(0).periods
    let sessionIdx = idx / initialSession.count
    let initialTick = sessionIdx * sessionTickCount
    return sessionAt(initialTick)
  }

  func targetTick(at tick: Tick, workPeriodsPerDay: Int) -> Tick {
    let index = targetZoneIndexAt(tick, workPeriodsPerDay) + 1
    let target = max(0, workPeriodsPerDay) * index
    let targetWorkPeriod = nthWorkPeriod(target)

    if targetWorkPeriod.tickRange.upperBound < tick {
      // If we are here, we are in the "no mans land" between the last work
      // period of this zone and the start of the next work period. In other
      // words, we are in a final long break... so we need to skip ahead to
      // the first work period of the next zone and return that zone's target
      // tick...
      let index = index + 1
      let target = max(0, workPeriodsPerDay) * index
      return nthWorkPeriod(target).tickRange.upperBound
    }

    return targetWorkPeriod.tickRange.upperBound
  }

  func halfwayTargetTick(at tick: Tick, workPeriodsPerDay: Int) -> Tick {
    let multiplier = targetZoneIndexAt(tick, workPeriodsPerDay) + 1
    let targetWordPeriodIdx = (max(0, workPeriodsPerDay) * multiplier) - (workPeriodsPerDay / 2)
    let targetWorkPeriod = nthWorkPeriod(targetWordPeriodIdx)

    if targetWorkPeriod.tickRange.upperBound < tick {
      let multiplier = multiplier + 1
      let targetWordPeriodIdx = (max(0, workPeriodsPerDay) * multiplier) - (workPeriodsPerDay / 2)
      let targetWorkPeriod = nthWorkPeriod(targetWordPeriodIdx)
      return targetWorkPeriod.tickRange.upperBound - (workPeriodsPerDay.isMultiple(of: 2)
        ? 0
        : (Tick(work.asSeconds) / 2) + 1)
    }

    return targetWorkPeriod.tickRange.upperBound - (workPeriodsPerDay.isMultiple(of: 2)
      ? 0
      : (Tick(work.asSeconds) / 2) + 1)
  }

  func targetZoneIndexAt(_ tick: Tick, _ workPeriodsPerZoneCount: Int) -> Int {
    let periodIndex = indexOfPeriodAt(tick)
    guard periodIndex >= 0 else { return 0 }
    guard workPeriodsPerZoneCount > 0 else { return 0 }

    return periodIndex / (workPeriodsPerZoneCount * 2)
  }

  func indexOfPeriodAt(_ tick: Tick) -> Int {
    let (sessionPeriods, sessionIdx) = sessionAt(tick)

    return (sessionPeriods.indexOfPeriodAt(tick)) + (sessionIdx * sessionPeriods.count)
  }
}

public extension WorkPattern {
  func nextStopTickAfter(tick: Tick,
                         stoppingAtNearestBreak: Bool,
                         stoppingAtNearestWorkPeriod: Bool)
    -> Tick
  {
    switch (stoppingAtNearestBreak, stoppingAtNearestWorkPeriod) {
    case (false, false):
      return Tick.max - 1
    case (true, true):
      return nextPeriodAt(tick).tickRange.lowerBound
    case (true, false):
      let period = periodAt(tick)
      return period.kind == .work
        ? period.tickRange.upperBound + 1
        : nextPeriodAt(tick).tickRange.upperBound + 1
    case (false, true):
      let period = periodAt(tick)
      return period.kind != .work
        ? period.tickRange.upperBound + 1
        : nextPeriodAt(tick).tickRange.upperBound + 1
    }
  }
}

extension Ticks {
  var duration: Duration {
    count.seconds - 1.seconds
  }
}

public extension Duration {
  var tickCount: TickCount { Tick(asSeconds) + 1 }
  var tickRange: Ticks { .zero ... Tick(asSeconds) }
}
