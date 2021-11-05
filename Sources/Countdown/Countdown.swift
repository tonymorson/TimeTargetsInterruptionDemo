import Foundation
import Ticks

public struct Countdown: Equatable, Codable {
  public var ticks: Ticks
  public var startTime: Date

  public init(ticks: Ticks, startTime: Date) {
    self.ticks = ticks
    self.startTime = startTime
  }
}

public extension Countdown {
  static var zero: Countdown {
    Countdown(ticks: 0 ... 0, startTime: .init(timeIntervalSince1970: 0))
  }
}

public extension Countdown {
  mutating func start(at timestamp: Date, maxTick: Tick = Tick.max - 1) {
    let tick = tick(at: timestamp)

    ticks = tick ... max(tick, maxTick)
    startTime = timestamp
  }

  mutating func stop(at timestamp: Date) {
    let tick = tick(at: timestamp)

    ticks = tick ... tick
    startTime = timestamp
  }

  mutating func toggle(at timestamp: Date, maxTick: Tick = Tick.max - 1) {
    isCountingDown(at: timestamp)
      ? stop(at: timestamp)
      : start(at: timestamp, maxTick: maxTick)
  }
}

public extension Countdown {
  var startTick: Tick {
    ticks.lowerBound
  }

  var stopTick: Tick {
    ticks.upperBound
  }

  var stopTime: Date {
    startTime.addingTimeInterval(Double(ticks.count))
  }

  func isCountingDown(at tick: Tick) -> Bool {
    if ticks.lowerBound == ticks.upperBound { return false }

    if tick < ticks.lowerBound { return false }
    if tick >= ticks.upperBound { return false }

    return true
  }

  func isCountingDown(at timestamp: Date) -> Bool {
    let tick = tick(at: timestamp)

    return isCountingDown(at: tick)
  }

  func tick(at timestamp: Date) -> Tick {
    ticks.clamp(Tick(timestamp.timeIntervalSince(startTime)) + ticks.lowerBound)
  }

  func time(at tick: Tick) -> Date {
    startTime.addingTimeInterval(Double(tick - startTick))
  }
}

private extension ClosedRange where Bound == Tick {
  func clamp(_ value: Tick) -> Tick {
    Swift.min(Swift.max(value, lowerBound), upperBound)
  }
}
