import ComposableArchitecture
import Foundation
import Ticks
import Timeline

public func tickEffect(for timeline: Timeline, at tick: Tick, on scheduler: AnySchedulerOf<DispatchQueue>) -> Effect<DispatchQueue.SchedulerTimeType, Never> {
  struct TimerId: Hashable {}

  return timeline.countdown.isCountingDown(at: tick)
    ? Effect.timer(id: TimerId(), every: 1, on: scheduler) .cancellable(id: TimerId(), cancelInFlight: true)
    : .cancel(id: TimerId())
}
