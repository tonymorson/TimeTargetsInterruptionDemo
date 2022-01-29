import ComposableArchitecture
import Foundation
import Timeline
import XCTest

@testable import UserActivity

class UserActivityTests: XCTestCase {
  let mainRunLoop = RunLoop.test

  func testEnvironment() -> UserActivityEnvironment {
    UserActivityEnvironment(date: { self.mainRunLoop.now.date },
                            scheduler: mainRunLoop.eraseToAnyScheduler())
  }

  func test1() {
    let store = TestStore(initialState: .basicTestSchedule,
                          reducer: UserActivityReducer,
                          environment: testEnvironment())

    store.send(.resume) {
      $0.history.append(.init())
      $0.history[0].countdown.ticks = 0 ... 334
    }

    store.send(.pause) {
      $0.history.append(.init())
    }
  }

  func test2() {
    let store = TestStore(initialState: .basicTestSchedule,
                          reducer: UserActivityReducer,
                          environment: testEnvironment())

    store.send(.resume) {
      $0.history.append(.init())
      $0.history[0].countdown.ticks = 0 ... 334
    }

    mainRunLoop.advance(by: 6)

    store.receive(.timerTicked) { $0.tick = 1 }
    store.receive(.timerTicked) { $0.tick = 2 }
    store.receive(.timerTicked) { $0.tick = 3 }
    store.receive(.timerTicked) { $0.tick = 4 }
    store.receive(.timerTicked) { $0.tick = 5 }
    store.receive(.timerTicked) { $0.tick = 6 }

    store.send(.pause) {
      $0.history.append(.init())
      $0.history[1].countdown.ticks = 6 ... 6
      $0.history[1].countdown.startTime = .init(timeIntervalSince1970: 6)
    }
  }
}

extension UserActivityState {
  static var basicTestSchedule: UserActivityState {
    .init(tick: .zero, history: [])
  }
}
