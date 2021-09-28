import Countdown
import Foundation
import Periods
import Ticks

public struct Timeline: Equatable, Codable {
  public var countdown: Countdown
  public var dailyTarget: Int
  public var periods: WorkPattern
  public var resetWorkOnStop: Bool
  public var stopOnBreak: Bool
  public var stopOnWork: Bool

  public init(countdown: Countdown = .zero,
              dailyTarget: Int = 10,
              resetWorkOnStop: Bool = false,
              periods: WorkPattern = .standard,
              stopOnBreak: Bool = false,
              stopOnWork: Bool = false)
  {
    self.countdown = countdown
    self.dailyTarget = dailyTarget
    self.resetWorkOnStop = resetWorkOnStop
    self.periods = periods
    self.stopOnBreak = stopOnBreak
    self.stopOnWork = stopOnWork
  }

  public func period(at date: () -> Date) -> Period {
    let tick = countdown.tick(at: date())
    return periods.periodAt(tick)
  }

  public func nextPeriod(at date: () -> Date) -> Period {
    let tick = period(at: date).tickRange.upperBound + 1
    return periods.periodAt(tick)
  }

  public mutating func resumeCountdown(from date: () -> Date) {
    countdown.start(at: date(), maxTick: nextStopTick(at: date))
  }

  public mutating func pauseCountdown(at date: () -> Date) {
    countdown.stop(at: date())
  }

  public mutating func toggleCountdown(at date: () -> Date) {
    countdown.toggle(at: date(), maxTick: nextStopTick(at: date))
  }

  public mutating func moveCountdownToStartOfCurrentPeriod(at date: () -> Date) {
    let currentPeriod = period(at: date)
    let lowerTickBound = currentPeriod.tickRange.lowerBound
    let upperTickBound = nextStopTick(after: currentPeriod.firstTick, at: date)

    countdown.ticks = lowerTickBound ... upperTickBound
    countdown.startTime = date()
  }

  public mutating func moveCountdownToStartOfNextPeriod(at date: () -> Date) {
    let nextPeriod = nextPeriod(at: date)
    let lowerTickBound = nextPeriod.tickRange.lowerBound
    let upperTickBound = nextStopTick(after: nextPeriod.firstTick, at: date)

    countdown.ticks = lowerTickBound ... upperTickBound
    countdown.startTime = date()
  }

  public mutating func resetCountdownToTickZero(date: () -> Date) {
    countdown.ticks = 0 ... 0
    countdown.startTime = date()
  }

  public func nextStopTick(at date: () -> Date) -> Tick {
    let currentTick = countdown.tick(at: date())
    let nextStopTick = periods.nextStopTickAfter(tick: currentTick,
                                                 stoppingAtNearestBreak: stopOnBreak,
                                                 stoppingAtNearestWorkPeriod: stopOnWork)

    let nextTargetTick = nextTargetTickAfter(tick: currentTick, at: date)

    return nextStopTick >= nextTargetTick ? nextTargetTick : nextStopTick
  }

  public func nextStopTick(after tick: Tick, at _: () -> Date) -> Tick {
    let nextStopTick = periods.nextStopTickAfter(tick: tick,
                                                 stoppingAtNearestBreak: stopOnBreak,
                                                 stoppingAtNearestWorkPeriod: stopOnWork)

    return nextStopTick
  }

  func nextTargetTickAfter(tick: Tick, at _: () -> Date) -> Tick {
    periods.targetTick(at: tick, workPeriodsPerDay: dailyTarget) + 1
  }
}

public extension Array where Element == Period {
  func workProgress(at tick: Tick) -> Double {
    guard !isEmpty else { return 0.0 }

    let periodTickRanges = filter(\.isWorkPeriod)
      .map(\.tickRange)

    let totals = periodTickRanges
      .reduce(0.0) { $0 + $1.progress(at: tick) }

    return totals / Double(periodTickRanges.count)
  }
}

public extension WorkPattern {
  func targetProgressAt(_ tick: Tick, _ dailyTarget: Int) -> Double {
    let (currentSession, sessionID) = sessionAt(tick)
    let sessionProgress = currentSession.workProgress(at: tick)
    let sessionsProgress = sessionProgress + 1.0 * Double(sessionID)

    return sessionsProgress * Double(numWorkPeriods) / Double(dailyTarget)
  }
}
