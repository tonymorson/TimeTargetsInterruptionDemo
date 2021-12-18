import Foundation

public extension Array where Element == Period {
  func periodAt(tick: Tick) -> Period? {
    guard let idx = (map(\.tickRange).firstIndex { $0.contains(tick) })
    else { return nil }

    return self[idx]
  }

  func periodAfterPeriodAt(tick: Tick) -> Period? {
    guard let idx = (map(\.tickRange).firstIndex { $0.contains(tick) })
    else { return nil }

    guard idx < count - 1
    else { return nil }

    return self[idx + 1]
  }

  func advancingAllTickRanges(by tick: Tick) -> [Period] {
    map(advance(by: tick))
  }

  func resequenced() -> Self {
    zip(map(\.kind), map(\.tickRange).resequenced())
      .map(Period.init)
  }

  func indexOfPeriodAt(_ tick: Tick) -> Int {
    map(\.tickRange)
      .firstIndex { $0.contains(tick) }!
  }
}

public extension Array where Element == Ticks {
  func resequenced() -> Self {
    reduce([], adjoinTickRanges)
  }
}

public extension Array where Element == [Period] {
  func resequenced() -> Self {
    let localResequenced = map { $0.resequenced() }

    var resequenced: [[Period]] = []

    for session in localResequenced {
      resequenced.append(session.advancingAllTickRanges(by: (resequenced.last?.last?.tickRange.upperBound ?? -1) + 1))
    }

    return resequenced
  }
}

//// MARK: - Curried functions for point free use

public func advance(by tick: Tick) -> (Period) -> Period {
  { period in
    Period(kind: period.kind,
           tickRange: period.tickRange.advanced(by: tick))
  }
}

public func adjoinTickRanges(acc: [Ticks], range: Ticks) -> [Ticks] {
  let lowerBound = (acc.last?.upperBound ?? -1) + 1

  return acc + [lowerBound ... lowerBound + range.count - 1]
}
