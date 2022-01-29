import Foundation

public typealias Tick = Int
public typealias Ticks = ClosedRange<Tick>
public typealias TickCount = Int

public extension Ticks {
  func advanced(by n: Bound.Stride) -> Self {
    lowerBound.advanced(by: n) ... upperBound.advanced(by: n)
  }

  func progress(at tick: Tick) -> Double {
    guard tick > lowerBound else { return 0.0 }
    guard tick < upperBound else { return 1.0 }

    return ((1.0 / Double(count - 1) * Double(tick - lowerBound)) * 100) / 100
  }
}
