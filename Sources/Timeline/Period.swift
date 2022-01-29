import Foundation

public struct Period: Codable, Equatable {
  public enum Kind: Int, Codable {
    case work
    case shortBreak
    case longBreak
  }

  public let kind: Kind
  public let tickRange: Ticks

  public init(kind: Period.Kind, tickRange: Ticks) {
    self.kind = kind
    self.tickRange = tickRange
  }

  public init(kind: Period.Kind, duration: Duration) {
    self.kind = kind
    tickRange = 0 ... Int(duration.asSeconds)
  }

  public var isWorkPeriod: Bool {
    kind == .work
  }

  public var firstTick: Tick {
    tickRange.lowerBound
  }

  public var lastTick: Tick {
    tickRange.upperBound
  }
}
