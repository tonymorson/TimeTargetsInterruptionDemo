import ComposableArchitecture
import Foundation
import PromptsFeature
import XCTest

@testable import PromptsFeature

public extension RunLoop {
  /// A test scheduler of run loops.
  static var testLoopAdjustingForTimezoneDependency: TestSchedulerOf<RunLoop> {
    let offset = TimeZone.current.secondsFromGMT()
    return .init(now: .init(.init(timeIntervalSince1970: TimeInterval(-offset))))
  }
}

class UninterruptedPromptsFeatureTests: XCTestCase {
  // Create a test scheduler.
  let mainRunLoop = RunLoop.testLoopAdjustingForTimezoneDependency

  func testFirstWorkPeriod() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 0)

    viewStore.send(.timeline(.startSchedule)) {
      $0.title = annotated(title: "Started work period.")
      $0.subtitle = annotated(subtitle: "Next break at 12:00 AM.")
      $0.actions = [.pauseWorkPeriod, .skipToNextBreak]
    }

    mainRunLoop.advance(by: .seconds(25))

    viewStore.receive(.timeline(.timerTicked)) {
      $0.actions = [.pauseWorkPeriod, .skipToNextBreak, .restartWorkPeriod]
    }

    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))

    viewStore.receive(.timeline(.timerTicked)) {
      $0.title = annotated(title: " ")
    }

    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))

    viewStore.receive(.timeline(.timerTicked)) {
      $0.title = annotated(title: "Prepare to wind down work period soon.")
    }

    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))

    viewStore.receive(.timeline(.timerTicked)) {
      $0.title = annotated(title: " ")
    }

    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))

    viewStore.stopTimer()
  }

  func testFirstBreak() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 1)

    viewStore.send(.timeline(.startBreak)) {
      $0.title = annotated(title: "Started break.")
      $0.subtitle = annotated(subtitle: "Next work period at 12:00 AM.")
      $0.actions = [.pauseBreak, .skipToNextWorkPeriod]
    }

    mainRunLoop.advance(by: .seconds(5))

    viewStore.receive(.timeline(.timerTicked)) {
      $0.actions = [.pauseBreak, .skipToNextWorkPeriod, .restartBreak]
    }

    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))

    viewStore.receive(.timeline(.timerTicked)) {
      $0.title = annotated(title: " ")
    }

    viewStore.receive(.timeline(.timerTicked))

    viewStore.stopTimer()
  }

  func testFifthWorkPeriod() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 8)

    viewStore.send(.timeline(.startWorkPeriod)) {
      $0.title = annotated(title: "Started work period.")
      $0.subtitle = annotated(subtitle: "Next break at 12:02 AM.")
      $0.actions = [.pauseWorkPeriod, .skipToNextBreak]
    }

    mainRunLoop.advance(by: .seconds(25))

    viewStore.receive(.timeline(.timerTicked)) { $0.actions = [.pauseWorkPeriod, .skipToNextBreak, .restartWorkPeriod] }
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))

    viewStore.receive(.timeline(.timerTicked)) {
      $0.title = annotated(title: " ")
    }

    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))

    viewStore.receive(.timeline(.timerTicked)) {
      $0.title = annotated(title: "Prepare to wind down work period soon.")
    }

    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))

    viewStore.receive(.timeline(.timerTicked)) {
      $0.title = annotated(title: " ")
    }

    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))

    viewStore.stopTimer()
  }

  func testFifthBreak() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 9)

    viewStore.send(.timeline(.startBreak)) {
      $0.title = annotated(title: "Started break.")
      $0.subtitle = annotated(subtitle: "Next work period at 12:02 AM.")
      $0.actions = [.pauseBreak, .skipToNextWorkPeriod]
    }

    mainRunLoop.advance(by: .seconds(5))

    viewStore.receive(.timeline(.timerTicked)) { $0.actions = [.pauseBreak, .skipToNextWorkPeriod, .restartBreak] }
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked))
    viewStore.receive(.timeline(.timerTicked)) { $0.title = annotated(title: " ") }
    viewStore.receive(.timeline(.timerTicked))

    viewStore.stopTimer()
  }

  private func viewStorePausedAtStartOfPeriod(nth: Int) -> TestStore<PromptsState, PromptsView.ViewState, PromptsAction, PromptsView.ViewAction, PromptsEnvironment> {
    // Create some initial state.
    var initialState = PromptsState()

    // Find the nth period we are interested in.
    let period = initialState.timeline.periods.periodAtIdx(nth)

    // Modify the initial state to paused it at the first tick of the nth period.
    var aTimeline = initialState.timeline
    aTimeline.countdown.ticks = period.firstTick ... period.firstTick
    initialState.userActivity.history = [aTimeline]
    initialState.userActivity.tick = period.firstTick

    // Make an offset so our schedule emits the right time during tests.
    let offset = Double(period.firstTick)

    // Create a test environment that emits the right time on its scheduler.
    let testEnvironment = PromptsEnvironment(date: { self.mainRunLoop.now.date + offset },
                                             scheduler: mainRunLoop.eraseToAnyScheduler())

    // Create a test store using the modified initial state and test environment.
    let testStore = TestStore(initialState: initialState,
                              reducer: promptsReducer,
                              environment: testEnvironment)

    // Scope the store down to the view model and return it.
    return testStore.scope(state: PromptsView.ViewState.init,
                           action: PromptsAction.init)
  }
}

class FirstPeriodTicks: XCTestCase {
  // Create a test scheduler.
  let mainRunLoop = RunLoop.test

  func testFirstTickOfEachPeriodWhilePaused() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 0)

    viewStore.send(.timeline(.pauseBreak)) {
      $0.title = annotated(title: "Ready to start?")
      $0.subtitle = annotated(subtitle: "You have 10 work periods remaining.")
      $0.actions = [.startSchedule]
    }

    viewStore.send(.timeline(.skipToNextBreak)) {
      $0.title = annotated(title: "Ready for a break?")
      $0.subtitle = annotated(subtitle: "You have worked 25 seconds with no break so far.")
      $0.actions = [.startBreak, .skipToNextWorkPeriod]
    }

    viewStore.send(.timeline(.skipToNextWorkPeriod)) {
      $0.title = annotated(title: "Ready to start another work period?")
      $0.subtitle = annotated(subtitle: "You have 9 work periods remaining.")
      $0.actions = [.startWorkPeriod, .skipToNextBreak]
    }

    viewStore.send(.timeline(.skipToNextBreak)) {
      $0.title = annotated(title: "Ready for a break?")
      $0.subtitle = annotated(subtitle: "You have worked 50 seconds with 1 break so far.")
      $0.actions = [.startBreak, .skipToNextWorkPeriod]
    }

    viewStore.send(.timeline(.skipToNextWorkPeriod)) {
      $0.title = annotated(title: "Ready to start another work period?")
      $0.subtitle = annotated(subtitle: "You have 8 work periods remaining.")
      $0.actions = [.startWorkPeriod, .skipToNextBreak]
    }

    viewStore.send(.timeline(.skipToNextBreak)) {
      $0.title = annotated(title: "Ready for a break?")
      $0.subtitle = annotated(subtitle: "You have worked 1 minute, 15 seconds with 2 breaks so far.")
      $0.actions = [.startBreak, .skipToNextWorkPeriod]
    }

    viewStore.send(.timeline(.skipToNextWorkPeriod)) {
      $0.title = annotated(title: "Ready to start another work period?")
      $0.subtitle = annotated(subtitle: "You have 7 work periods remaining.")
      $0.actions = [.startWorkPeriod, .skipToNextBreak]
    }

    viewStore.send(.timeline(.skipToNextBreak)) {
      $0.title = annotated(title: "Ready for a break?")
      $0.subtitle = annotated(subtitle: "You have worked 1 minute, 40 seconds with 3 breaks so far.")
      $0.actions = [.startBreak, .skipToNextWorkPeriod]
    }

    viewStore.send(.timeline(.skipToNextWorkPeriod)) {
      $0.title = annotated(title: "Ready to start another work period?")
      $0.subtitle = annotated(subtitle: "You have 6 work periods remaining.")
      $0.actions = [.startWorkPeriod, .skipToNextBreak]
    }

    viewStore.send(.timeline(.skipToNextBreak)) {
      $0.title = annotated(title: "Ready for a break?")
      $0.subtitle = annotated(subtitle: "You have worked 2 minutes, 5 seconds with 4 breaks so far.")
      $0.actions = [.startBreak, .skipToNextWorkPeriod]
    }

    viewStore.send(.timeline(.skipToNextWorkPeriod)) {
      $0.title = annotated(title: "Ready to start another work period?")
      $0.subtitle = annotated(subtitle: "You have 5 work periods remaining.")
      $0.actions = [.startWorkPeriod, .skipToNextBreak]
    }

    viewStore.send(.timeline(.skipToNextBreak)) {
      $0.title = annotated(title: "Ready for a break?")
      $0.subtitle = annotated(subtitle: "You have worked 2 minutes, 30 seconds with 5 breaks so far.")
      $0.actions = [.startBreak, .skipToNextWorkPeriod]
    }

    viewStore.send(.timeline(.skipToNextWorkPeriod)) {
      $0.title = annotated(title: "Ready to start another work period?")
      $0.subtitle = annotated(subtitle: "You have 4 work periods remaining.")
      $0.actions = [.startWorkPeriod, .skipToNextBreak]
    }

    viewStore.send(.timeline(.skipToNextBreak)) {
      $0.title = annotated(title: "Ready for a break?")
      $0.subtitle = annotated(subtitle: "You have worked 2 minutes, 55 seconds with 6 breaks so far.")
      $0.actions = [.startBreak, .skipToNextWorkPeriod]
    }

    viewStore.send(.timeline(.skipToNextWorkPeriod)) {
      $0.title = annotated(title: "Ready to start another work period?")
      $0.subtitle = annotated(subtitle: "You have 3 work periods remaining.")
      $0.actions = [.startWorkPeriod, .skipToNextBreak]
    }

    viewStore.send(.timeline(.skipToNextBreak)) {
      $0.title = annotated(title: "Ready for a break?")
      $0.subtitle = annotated(subtitle: "You have worked 3 minutes, 20 seconds with 7 breaks so far.")
      $0.actions = [.startBreak, .skipToNextWorkPeriod]
    }

    viewStore.send(.timeline(.skipToNextWorkPeriod)) {
      $0.title = annotated(title: "Ready to start another work period?")
      $0.subtitle = annotated(subtitle: "You have 2 work periods remaining.")
      $0.actions = [.startWorkPeriod, .skipToNextBreak]
    }

    viewStore.send(.timeline(.skipToNextBreak)) {
      $0.title = annotated(title: "Ready for a break?")
      $0.subtitle = annotated(subtitle: "You have worked 3 minutes, 45 seconds with 8 breaks so far.")
      $0.actions = [.startBreak, .skipToNextWorkPeriod]
    }

//    viewStore.send(.timeline(.skipToNextWorkPeriod)) {
    // #warning("fix test")
//      $0.title = annotated(title: "Ready to start another work period?")
//      $0.subtitle = annotated(subtitle: "You have 1 work period remaining.")
//      $0.actions = [.startWorkPeriod, .skipToNextBreak]
//    }
//
//    viewStore.send(.timeline(.skipToNextBreak)) {
    // #warning("fix test")
//      $0.title = annotated(title: "Ready for a break?")
//      $0.subtitle = annotated(subtitle: "You have worked 4 minutes, 10 seconds with 9 breaks so far.")
//      $0.actions = [.startBreak, .skipToNextWorkPeriod]
//    }
//
//    viewStore.send(.timeline(.skipToNextWorkPeriod)) {
    // #warning("fix test")
//      $0.title = annotated(title: "Ready to start another work period?")
//      $0.subtitle = annotated(subtitle: "You have blown past your target by 1 work period.")
//      $0.actions = [.startWorkPeriod, .skipToNextBreak]
//    }
  }

  private func viewStorePausedAtStartOfPeriod(nth: Int) -> TestStore<PromptsState, PromptsView.ViewState, PromptsAction, PromptsView.ViewAction, PromptsEnvironment> {
    // Create some initial state.
    var initialState = PromptsState()

    // Find the nth period we are interested in.
    let period = initialState.timeline.periods.periodAtIdx(nth)

    // Modify the initial state to paused it at the first tick of the nth period.
    var aTimeline = initialState.timeline
    aTimeline.countdown.ticks = period.firstTick ... period.firstTick
    initialState.userActivity.history = [aTimeline]
    initialState.userActivity.tick = period.firstTick

    // Make an offset so our schedule emits the right time during tests.
    let offset = Double(period.firstTick)

    // Create a test environment that emits the right time on its scheduler.
    let testEnvironment = PromptsEnvironment(date: { self.mainRunLoop.now.date + offset },
                                             scheduler: mainRunLoop.eraseToAnyScheduler())

    // Create a test store using the modified initial state and test environment.
    let testStore = TestStore(initialState: initialState,
                              reducer: promptsReducer,
                              environment: testEnvironment)

    // Scope the store down to the view model and return it.
    return testStore.scope(state: PromptsView.ViewState.init,
                           action: PromptsAction.init)
  }
}

class IdempotencyTests: XCTestCase {
  // Create a test scheduler.
  let mainRunLoop = RunLoop.testLoopAdjustingForTimezoneDependency

  func testPauseIsIdempotent() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 0)

    viewStore.send(.timeline(.pauseBreak)) {
      $0.title = annotated(title: "Ready to start?")
      $0.subtitle = annotated(subtitle: "You have 10 work periods remaining.")
      $0.actions = [.startSchedule]
    }

    viewStore.send(.timeline(.pauseBreak))
    viewStore.send(.timeline(.pauseBreak))
    viewStore.send(.timeline(.pauseBreak))
    viewStore.send(.timeline(.pauseBreak))
    viewStore.send(.timeline(.pauseBreak))
  }

  func testResumeIsIdempotent() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 0)

    viewStore.send(.timeline(.startSchedule)) {
      $0.title = annotated(title: "Started work period.")
      $0.subtitle = annotated(subtitle: "Next break at 12:00 AM.")
      $0.actions = [.pauseWorkPeriod, .skipToNextBreak]
    }

    viewStore.send(.timeline(.startSchedule))
    viewStore.send(.timeline(.startSchedule))
    viewStore.send(.timeline(.startSchedule))
    viewStore.send(.timeline(.startSchedule))
    viewStore.send(.timeline(.startSchedule))

    viewStore.stopTimer()
  }

  func testResumeIsIdempotent2() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 0)

    viewStore.send(.timeline(.startSchedule)) {
      $0.title = annotated(title: "Started work period.")
      $0.subtitle = annotated(subtitle: "Next break at 12:00 AM.")
      $0.actions = [.pauseWorkPeriod, .skipToNextBreak]
    }

    mainRunLoop.advance(by: .seconds(3))

    viewStore.receive(.timeline(.timerTicked)) {
      $0.actions = [.pauseWorkPeriod, .skipToNextBreak, .restartWorkPeriod]
    }

    viewStore.receive(.timeline(.timerTicked)) {
      $0.actions = [.pauseWorkPeriod, .skipToNextBreak, .restartWorkPeriod]
      viewStore.receive(.timeline(.timerTicked)) {
        $0.actions = [.pauseWorkPeriod, .skipToNextBreak, .restartWorkPeriod]
      }
    }

    viewStore.send(.timeline(.resumeWorkPeriod))
    viewStore.send(.timeline(.resumeWorkPeriod))

    viewStore.stopTimer()
  }

  private func viewStorePausedAtStartOfPeriod(nth: Int) -> TestStore<PromptsState, PromptsView.ViewState, PromptsAction, PromptsView.ViewAction, PromptsEnvironment> {
    // Create some initial state.
    var initialState = PromptsState()

    // Find the nth period we are interested in.
    let period = initialState.timeline.periods.periodAtIdx(nth)

    // Modify the initial state to paused it at the first tick of the nth period.
    var aTimeline = initialState.timeline
    aTimeline.countdown.ticks = period.firstTick ... period.firstTick
    initialState.userActivity.history = [aTimeline]
    initialState.userActivity.tick = period.firstTick

    // Make an offset so our schedule emits the right time during tests.
    let offset = Double(period.firstTick)

    // Create a test environment that emits the right time on its scheduler.
    let testEnvironment = PromptsEnvironment(date: { self.mainRunLoop.now.date + offset },
                                             scheduler: mainRunLoop.eraseToAnyScheduler())

    // Create a test store using the modified initial state and test environment.
    let testStore = TestStore(initialState: initialState,
                              reducer: promptsReducer,
                              environment: testEnvironment)

    // Scope the store down to the view model and return it.
    return testStore.scope(state: PromptsView.ViewState.init,
                           action: PromptsAction.init)
  }
}
