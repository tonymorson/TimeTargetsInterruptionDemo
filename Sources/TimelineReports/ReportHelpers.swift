import Foundation
import Periods
import Ticks

public extension Report {
  var periodHeadline: String {
    describeTimeRemaining(periodTicksRemaining)
  }

  var sessionHeadline: String {
    "\(sessionWorkPeriodsVisitedCount) of \(numWorkPeriodsInSession)"
  }

  var targetHeadline: String {
    percentDescription(targetProgress)
  }

  var periodUpper: (String, String) {
    currentPeriod.isWorkPeriod
      ? ("WORK", "PERIOD")
      : (currentPeriod.kind == .shortBreak ? "SHORT" : "LONG", "BREAK")
  }

  func sessionUpper(_ timestamp: Date) -> (String, String) {
    (partOfDayDescription(timestamp), "WORK PERIODS")
  }

  var targetUpper: (String, String) {
    ("TODAY'S", "TARGET")
  }

  var periodLower: String {
    "remaining"
  }

  var sessionLower: String {
    currentPeriod.isWorkPeriod ? "in progress" : "completed"
  }

  var targetLower: String {
    "complete"
  }

  var periodFooter: String {
    describeApproximately(periodDuration).uppercased()
  }

  var sessionFooter: String {
    describeApproximately(sessionDuration).uppercased()
  }

  var targetFooter: String {
    describeApproximately(targetDuration).uppercased()
  }
}

private extension Measurement where UnitType == UnitDuration {
  var asTimeInterval: TimeInterval {
    converted(to: .seconds).value
  }
}

private var durationFormatter: DateComponentsFormatter {
  let formatter = DateComponentsFormatter()
  formatter.unitsStyle = .full
  formatter.allowedUnits = [.hour, .minute, .second]
  formatter.zeroFormattingBehavior = .dropAll
//    formatter.includesApproximationPhrase = duration > 1.hours

  return formatter
}

private func describeApproximately(_ duration: Measurement<UnitDuration>) -> String {
  durationFormatter.includesApproximationPhrase = duration > 1.hours

  if duration <= 1.hours {
    return durationFormatter.string(from: duration.asTimeInterval) ?? ""
  }

  let remainingSeconds = duration.asSeconds.remainder(dividingBy: 1.hours.asTimeInterval)

  if remainingSeconds == 0 { return describe(duration) }

  if remainingSeconds < (30 * 60) {
    return durationFormatter.string(from: duration.asTimeInterval - Double(remainingSeconds)) ?? ""
  }

  return durationFormatter.string(from: duration.asTimeInterval + Double(remainingSeconds)) ?? ""
}

private func describe(_ duration: Measurement<UnitDuration>) -> String {
  durationFormatter.string(from: duration.asTimeInterval) ?? ""
}

private func describeTimeRemaining(_ tickCount: TickCount) -> String {
  let seconds = tickCount % 60
  let minutes = (tickCount / 60) % 60
  let hours = tickCount / 3600

  return hours > 0
    ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    : String(format: "%02d:%02d", minutes, seconds)
}

private let partOfDayDescription: (Date) -> String = {
  let calender = Calendar(identifier: .gregorian)
  let hourComponent = calender.component(.hour, from: $0)

  switch hourComponent {
  case 0 ... 2:
    return "LATE NIGHT"
  case 3 ... 5:
    return "EARLY HOURS"
  case 6 ... 8:
    return "EARLY MORNING"
  case 9 ... 10:
    return "MORNING"
  case 11 ... 11:
    return "LATE MORNING"
  case 12 ... 16:
    return "AFTERNOON"
  case 17 ... 17:
    return "LATE AFTERNOON"
  case 18 ... 20:
    return "EVENING"
  case 21 ... 22:
    return "NIGHT TIME"
  case 23 ... 23:
    return "LATE NIGHT"
  default:
    return ""
  }
}

private func percentDescription(_ progress: Double) -> String {
  percentNumberFormatter.string(from: NSNumber(value: progress)) ?? "\(Int((progress * 100.0).rounded(.toNearestOrAwayFromZero)))%"
}

private var percentNumberFormatter: NumberFormatter {
  let formatter = NumberFormatter()
  formatter.numberStyle = .percent
  formatter.minimumIntegerDigits = 1
  formatter.maximumFractionDigits = 0
  formatter.roundingMode = .halfUp

  return formatter
}
