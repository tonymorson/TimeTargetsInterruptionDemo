import Foundation
import Ticks

public struct Countdown: Equatable, Codable {
  public var ticks: Ticks
  public var startTime: Date
  public var endTime: Date { startTime.addingTimeInterval(Double(ticks.count)) }

  public init(ticks: Ticks, startTime: Date) {
    self.ticks = ticks
    self.startTime = startTime
  }
}

public extension Countdown {
  static var zero: Countdown {
    Countdown(ticks: 0 ... 0, startTime: Date.distantPast)
  }
}

public extension Countdown {
  mutating func start(at timestamp: Date, maxTick: Tick = Tick.max - 1) {
    let tick = self.tick(at: timestamp)

    ticks = tick ... max(tick, maxTick)
    startTime = timestamp
  }

  mutating func stop(at timestamp: Date) {
    let tick = self.tick(at: timestamp)

    ticks = tick ... tick
    startTime = timestamp
  }

  mutating func toggle(at timestamp: Date, maxTick: Tick = Tick.max - 1) {
    isCountingDown(at: timestamp) ? stop(at: timestamp) : start(at: timestamp, maxTick: maxTick)
  }
}

public extension Countdown {
  func isCountingDown(at timestamp: Date) -> Bool {
    let tick = self.tick(at: timestamp)

    return isCountingDown(at: tick)
  }

  func isCountingDown(at tick: Tick) -> Bool {
    if ticks.lowerBound == ticks.upperBound { return false }

    if tick < ticks.lowerBound { return false }
    if tick >= ticks.upperBound { return false }

    return true
  }

  func tick(at timestamp: Date) -> Tick {
    ticks.clamp(Tick(timestamp.timeIntervalSince(startTime)) + ticks.lowerBound)
  }

  var startTick: Tick {
    ticks.lowerBound
  }

  var stopTick: Tick {
    ticks.upperBound
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
