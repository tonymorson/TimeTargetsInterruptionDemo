import ComposableArchitecture
import Foundation
import PromptsFeature
import XCTest

@testable import PromptsFeature

class UninterruptedPromptsFeatureTests: XCTestCase {
  // Create a test scheduler.
  let mainRunLoop = RunLoop.test

  func testFirstWorkPeriod() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 0)

    viewStore.send(.timeline(.startSchedule)) {
      $0.title = annotated(title: "Started work period.")
      $0.subtitle = annotated(subtitle: "Next break at 1:00 AM.")
      $0.actions = [.pauseWorkPeriod, .skipToNextBreak]
    }

    mainRunLoop.advance(by: .seconds(25))

    viewStore.receive(.timerTicked) {
      $0.actions = [.pauseWorkPeriod, .skipToNextBreak, .restartWorkPeriod]
    }

    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)

    viewStore.receive(.timerTicked) {
      $0.title = annotated(title: " ")
    }

    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)

    viewStore.receive(.timerTicked) {
      $0.title = annotated(title: "Prepare to wind down work period soon.")
    }

    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)

    viewStore.receive(.timerTicked) {
      $0.title = annotated(title: " ")
    }

    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)

    viewStore.stopTimer()
  }

  func testFirstBreak() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 1)

    viewStore.send(.timeline(.startBreak)) {
      $0.title = annotated(title: "Started break.")
      $0.subtitle = annotated(subtitle: "Next work period at 1:00 AM.")
      $0.actions = [.pauseBreak, .skipToNextWorkPeriod]
    }

    mainRunLoop.advance(by: .seconds(5))

    viewStore.receive(.timerTicked) {
      $0.actions = [.pauseBreak, .skipToNextWorkPeriod, .restartBreak]
    }

    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)

    viewStore.receive(.timerTicked) {
      $0.title = annotated(title: " ")
    }

    viewStore.receive(.timerTicked)

    viewStore.stopTimer()
  }

  func testFifthWorkPeriod() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 8)

    viewStore.send(.timeline(.startWorkPeriod)) {
      $0.title = annotated(title: "Started work period.")
      $0.subtitle = annotated(subtitle: "Next break at 1:02 AM.")
      $0.actions = [.pauseWorkPeriod, .skipToNextBreak]
    }

    mainRunLoop.advance(by: .seconds(25))

    viewStore.receive(.timerTicked) { $0.actions = [.pauseWorkPeriod, .skipToNextBreak, .restartWorkPeriod] }
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)

    viewStore.receive(.timerTicked) {
      $0.title = annotated(title: " ")
    }

    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)

    viewStore.receive(.timerTicked) {
      $0.title = annotated(title: "Prepare to wind down work period soon.")
    }

    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)

    viewStore.receive(.timerTicked) {
      $0.title = annotated(title: " ")
    }

    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)

    viewStore.stopTimer()
  }

  func testFifthBreak() {
    let viewStore = viewStorePausedAtStartOfPeriod(nth: 9)

    viewStore.send(.timeline(.startBreak)) {
      $0.title = annotated(title: "Started break.")
      $0.subtitle = annotated(subtitle: "Next work period at 1:02 AM.")
      $0.actions = [.pauseBreak, .skipToNextWorkPeriod]
    }

    mainRunLoop.advance(by: .seconds(5))

    viewStore.receive(.timerTicked) { $0.actions = [.pauseBreak, .skipToNextWorkPeriod, .restartBreak] }
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked)
    viewStore.receive(.timerTicked) { $0.title = annotated(title: " ") }
    viewStore.receive(.timerTicked)

    viewStore.stopTimer()
  }

  private func viewStorePausedAtStartOfPeriod(nth: Int) -> TestStore<PromptsState, PromptsView.ViewState, PromptsAction, PromptsView.ViewAction, PromptsEnv> {
    // Create some initial state.
    var initialState = PromptsState()

    // Find the nth period we are interested in.
    let period = initialState.timeline.periods.periodAtIdx(nth)

    // Modify the initial state to paused it at the first tick of the nth period.
    initialState.timeline.countdown.ticks = period.firstTick ... period.firstTick

    // Make an offset so our schedule emits the right time during tests.
    let offset = Double(period.firstTick)

    // Create a test environment that emits the right time on its scheduler.
    let testEnvironment = PromptsEnv(date: { self.mainRunLoop.now.date + offset },
                                     mainRunLoop: mainRunLoop.eraseToAnyScheduler())

    // Create a test store using the modified initial state and test environment.
    let testStore = TestStore(initialState: initialState,
                              reducer: promptsReducer,
                              environment: testEnvironment)

    // Scope the store down to the view model and return it.
    return testStore.scope(state: PromptsView.ViewState.init,
                           action: PromptsAction.init)
  }
}

private func annotated(title: String) -> AttributedString {
  var title = AttributedString(title)
  title.font = UIFont.systemFont(ofSize: 24, weight: .light).rounded()
  title.foregroundColor = .systemRed

  return title
}

private func annotated(subtitle: String) -> AttributedString {
  var subtitle = AttributedString(subtitle)
  subtitle.font = UIFont.systemFont(ofSize: 18, weight: .light).rounded()
  subtitle.foregroundColor = .label

  return subtitle
}

extension TestStore where LocalState == PromptsView.ViewState,
  LocalAction == PromptsView.ViewAction
{
  func stopTimer() {
    send(.timeline(.resetSchedule)) {
      $0.title = annotated(title: "Ready to start?")
      $0.subtitle = annotated(subtitle: "You have 10 work periods remaining.")
      $0.actions = [.startSchedule]
    }
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
  }

  private func viewStorePausedAtStartOfPeriod(nth: Int) -> TestStore<PromptsState, PromptsView.ViewState, PromptsAction, PromptsView.ViewAction, PromptsEnv> {
    // Create some initial state.
    var initialState = PromptsState()

    // Find the nth period we are interested in.
    let period = initialState.timeline.periods.periodAtIdx(nth)

    // Modify the initial state to paused it at the first tick of the nth period.
    initialState.timeline.countdown.ticks = period.firstTick ... period.firstTick

    // Make an offset so our schedule emits the right time during tests.
    let offset = Double(period.firstTick)

    // Create a test environment that emits the right time on its scheduler.
    let testEnvironment = PromptsEnv(date: { self.mainRunLoop.now.date + offset },
                                     mainRunLoop: mainRunLoop.eraseToAnyScheduler())

    // Create a test store using the modified initial state and test environment.
    let testStore = TestStore(initialState: initialState,
                              reducer: promptsReducer,
                              environment: testEnvironment)

    // Scope the store down to the view model and return it.
    return testStore.scope(state: PromptsView.ViewState.init,
                           action: PromptsAction.init)
  }
}
