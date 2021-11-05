import Foundation
import Periods
import Ticks
import Timeline

struct LiveTimeline: Equatable, Codable {
  var currentTick: Tick
  let timeline: Timeline

  init(timeline: Timeline, currentTick: Tick = 0) {
    self.timeline = timeline
    self.currentTick = currentTick
  }
}

extension LiveTimeline {
  var isCountingDown: Bool {
    timeline.countdown.isCountingDown(at: currentTick)
  }

  var isPaused: Bool {
    !isCountingDown
  }

  var nextStopTick: Tick {
    min(
      timeline.periods.nextStopTickAfter(tick: currentTick,
                                         stoppingAtNearestBreak: timeline.stopOnBreak,
                                         stoppingAtNearestWorkPeriod: timeline.stopOnWork),
      nextTargetTick
    )
  }

  var numberOfBreaksTakenSoFar: Int {
    timeline.periods.periods(from: 0, to: currentTick).indexOfPeriodAt(currentTick) / 2
  }

  var isAtStartOfPeriod: Bool {
    currentTick == currentPeriod.firstTick
  }

  var isWaitingAtScheduleStart: Bool {
    currentTick == 0 && isPaused
  }
}

extension LiveTimeline {
  var sessionPeriods: [Period] {
    timeline.periods.sessionAt(currentTick).periods
  }

  var nextHalfwayTargetTick: Tick {
    timeline.periods.halfwayTargetTick(at: currentTick, workPeriodsPerDay: timeline.dailyTarget) + 1
  }

  func nextHalfwayTargetTickAfter(tick: Tick) -> Tick {
    timeline.periods.halfwayTargetTick(at: tick, workPeriodsPerDay: timeline.dailyTarget) + 1
  }

  var initialTargetTick: Tick {
    timeline.periods.targetTick(at: 0, workPeriodsPerDay: timeline.dailyTarget) + 1
  }

  var nextTargetTick: Tick {
    timeline.periods.targetTick(at: currentTick, workPeriodsPerDay: timeline.dailyTarget) + 1
  }

  func nextTargetTickAfter(tick: Tick) -> Tick {
    timeline.periods.targetTick(at: tick, workPeriodsPerDay: timeline.dailyTarget) + 1
  }

  var transitioningTicks: Set<Tick> {
    Set(
      timeline.periods
        .periods(from: currentTick, to: timeline.countdown.stopTick)
        .dropFirst()
        .map(\.tickRange.lowerBound)
    )
  }

  func setCurrentTick(to tick: Tick) -> LiveTimeline {
    var timeline = self
    timeline.currentTick = tick

    return timeline
  }
}

extension LiveTimeline {
  /// The period of the current tick.
  var currentPeriod: Period { timeline.periods.periodAt(currentTick) }

  /// The period immediately following the current period.
  var nextPeriod: Period { timeline.periods.nextPeriodAt(currentTick) }

  /// The period that initiated the countdown.
  var startPeriod: Period { timeline.periods.periodAt(timeline.countdown.startTick) }

  /// The period where the countdown will (or did) stop.
  var stopPeriod: Period { timeline.periods.periodAt(timeline.countdown.stopTick) }
  var startTick: Tick { timeline.countdown.startTick }
  var stopTick: Tick { timeline.countdown.stopTick }
}

extension LiveTimeline {
  var comingNext: Date {
    comingNext(after: currentTick)
  }

  func comingNext(after tick: Tick) -> Date {
    let nextPeriod = timeline.periods.nextPeriodAt(tick)
    return timeline.countdown.time(at: nextPeriod.tickRange.lowerBound)
  }
}

extension LiveTimeline {
  var isAtTickZero: Bool {
    currentTick == .zero
  }

  var isAtInitialTargetTick: Bool {
    currentTick == initialTargetTick
  }

  var isAtMultipleTargetTick: Bool {
    currentTick == nextTargetTickAfter(tick: startTick)
  }
}

extension Array where Element == Period {
  var firstTick: Tick {
    first?.firstTick ?? Tick.min
  }

  var lastTick: Tick {
    last?.lastTick ?? Tick.max
  }

  var firstWorkTick: Tick {
    filter(\.isWorkPeriod)
      .first?
      .firstTick ?? Tick.min
  }

  var lastWorkTick: Tick {
    filter(\.isWorkPeriod)
      .last?
      .lastTick ?? Tick.max
  }
}

extension LiveTimeline {
  enum Observation: Equatable {
    case atTickZero
    case fallingBehind
    case interruptedLongBreak
    case interruptedShortBreak
    case interruptedWork
    case comingNext
    case reachedInitialTarget
    case reachedInitialTargetMultiple
    case reachedSignificantProgress
    case readyToStartLongBreak
    case readyToStartShortBreak
    case readyToStartWork
    case remainingPeriodsToComplete
    case surpassedDailyGoal
    case timeForALongBreak
    case timeForAShortBreak
    case timeForWork
    case sessionRingClosingSoon
    case workRingClosingSoon
    case workRingClosed
    case workSoFar
    case none
  }

  var primaryObservation: Observation {
    if isCountingDown {
      switch currentPeriod.kind {
      case .work:
        return .timeForWork

      case .shortBreak:
        return .timeForAShortBreak

      case .longBreak:
        return .timeForALongBreak
      }
    } else {
      if isAtTickZero { return .atTickZero }
      if isAtInitialTargetTick { return .reachedInitialTarget }
      if isAtMultipleTargetTick { return .reachedInitialTargetMultiple }
      if isAtStartOfPeriod {
        switch currentPeriod.kind {
        case .work:
          return .readyToStartWork

        case .shortBreak:
          return .readyToStartShortBreak

        case .longBreak:
          return .readyToStartLongBreak
        }
      }
      switch currentPeriod.kind {
      case .work:
        return .interruptedWork

      case .shortBreak:
        return .interruptedShortBreak

      case .longBreak:
        return .interruptedLongBreak
      }
    }
  }

  var tertiaryObservation: Observation {
    var isBeyondDailyTarget: Bool {
      currentTick > initialTargetTick
    }

    var remainingPeriodsToCompleteDescription: Observation {
      isBeyondDailyTarget
        ? .surpassedDailyGoal
        : .remainingPeriodsToComplete
    }

    if isCountingDown {
      return .comingNext
    }

    if isAtInitialTargetTick {
      return .workRingClosed
    }

    if isAtStartOfPeriod, currentPeriod.isWorkPeriod {
      return isBeyondDailyTarget
        ? .surpassedDailyGoal
        : .remainingPeriodsToComplete
    }

    if isAtStartOfPeriod, !currentPeriod.isWorkPeriod {
      return .workSoFar
    }

    return .fallingBehind
  }

  var secondaryObservation: Observation {
    if progress.remainder(dividingBy: 1.0) == 0.5, !currentPeriod.isWorkPeriod { return .reachedSignificantProgress }

    if isCountingDown {
      let nextPeriodProgress = timeline.periods.targetProgressAt(nextPeriod.firstTick, timeline.dailyTarget)
      if nextPeriodProgress == 100.0 { return .workRingClosingSoon }
    }

    if isCountingDown {
      if nextPeriod.kind == .longBreak { return .sessionRingClosingSoon }
    }

    return .none
  }

  var describePrimaryObservation: String {
    describe(primaryObservation)
  }

  var describeSecondaryObservation: String {
    describe(secondaryObservation)
  }

  var describeTertiaryObservation: String {
    describe(tertiaryObservation)
  }
}

private extension LiveTimeline {
  func describe(_ type: Observation) -> String {
    switch type {
    case .atTickZero:
      return "Ready to start?"

    case .fallingBehind:

      var time = timeline.countdown.stopTime.distance(to: Date())

      switch time {
      case ...firstReminderTimeInterval:
        time = firstReminderTimeInterval
      case firstReminderTimeInterval ... secondReminderTimeInterval:
        time = secondReminderTimeInterval
      case secondReminderTimeInterval...:
        time = finalReminderTimeInterval
      default:
        time = finalReminderTimeInterval
      }

      let seconds = Double(time / 1)
      return seconds < 60
        ? "You will fall behind schedule shortly."
        : "You are \(minutesFormatter.string(from: seconds) ?? "falling") behind schedule."

    case .surpassedDailyGoal:
      return "You have surpassed your daily goal by \(abs(remainingPeriodsToComplete) + 1) work period\(abs(remainingPeriodsToComplete) == 0 ? "" : "s")."

    case .workRingClosed:
      return "Target ring closed!"

    case .reachedInitialTarget:
      return "Congratulations! Work target reached! 🎉"

    case .reachedInitialTargetMultiple:
      return "Congratulations! Work target reached again! 🎉"

    case .reachedSignificantProgress:
      return "You have reached \(describeProgress) of your goal ✊"

    case .remainingPeriodsToComplete:
      return "You have \(remainingPeriodsToComplete) \(remainingPeriodsToComplete == 1 ? "work period" : "work periods") remaining."

    case .comingNext:
      switch nextPeriod.kind {
      case .work:
        return "Next work period at \(Self.describeTimeBriefly(comingNext(after: currentTick)))."

      case .shortBreak:
        return "Next short break at \(Self.describeTimeBriefly(comingNext(after: currentTick)))."

      case .longBreak:
        return "Next long break at \(Self.describeTimeBriefly(comingNext(after: currentTick)))."
      }

    case .workSoFar:
      let formatter = DateComponentsFormatter()
      formatter.unitsStyle = .full
      formatter.allowedUnits = [.hour, .minute, .second]
      formatter.zeroFormattingBehavior = [.dropAll]

      let breakCount = numberOfBreaksTakenSoFar

      let timeWorkedSoFar = Double(breakCount + 1) * 120
      let formattedDuration = formatter.string(from: timeWorkedSoFar)?.lowercased() ?? ""
      let breakCountDescription = breakCount == 0
        ? "with no breaks"
        : breakCount == 1 ? "with \(breakCount) break" : "with \(breakCount) breaks"

      if breakCount == 0 {
        return "You have worked \(formattedDuration) \(breakCountDescription) so far."
      }
      return "You have worked \(formattedDuration) \(breakCountDescription) so far."

    case .timeForWork:
      return "Time for work."

    case .timeForAShortBreak:
      return "Time for a short break."

    case .timeForALongBreak:
      return "Time for a long break."

    case .readyToStartWork:
      return "Ready to start next work period?"

    case .readyToStartShortBreak:
      return "Ready for a short break?"

    case .readyToStartLongBreak:
      return "Ready for a long break?"

    case .interruptedWork:
      return "Work interrupted at \(Self.describeTimeBriefly(timeline.countdown.stopTime))."

    case .interruptedShortBreak:
      return "Break interrupted at \(Self.describeTimeBriefly(timeline.countdown.stopTime))."

    case .interruptedLongBreak:
      return "Break interrupted at \(Self.describeTimeBriefly(timeline.countdown.stopTime))."

    case .sessionRingClosingSoon:
//      return "\(sessionName(Date())) ring closing soon."
      return "Session ring closing soon."

    case .workRingClosingSoon:
      return "Work target ring closing soon."

    case .none:
      return ""
    }
  }

  private var remainingPeriodsToComplete: Int { timeline.dailyTarget - numberOfBreaksTakenSoFar }

  private static let describeTimeBriefly: (Date) -> String = { date in

    shortTimeFormatter.string(from: date)
  }

  private static var shortTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short

    return formatter
  }()
}

var minutesFormatter: DateComponentsFormatter = {
  let formatter = DateComponentsFormatter()
  formatter.allowedUnits = [.day, .hour, .minute]
  formatter.unitsStyle = .full
  formatter.maximumUnitCount = 5

  return formatter
}()

extension LiveTimeline {
  var progress: Double {
    timeline.periods.targetProgressAt(currentTick, timeline.dailyTarget)
  }

  var describeProgress: String {
    Self.percentNumberFormatter.string(from: NSNumber(value: progress)) ?? "\(Int((progress * 100.0).rounded(.toNearestOrAwayFromZero)))%"
  }

  static var percentNumberFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 0
    formatter.roundingMode = .halfUp

    return formatter
  }
}
