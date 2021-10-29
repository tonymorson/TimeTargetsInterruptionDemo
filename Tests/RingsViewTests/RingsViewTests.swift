import ComposableArchitecture
import Foundation
import RingsView
import XCTest

extension RingsEnvironment {
  static var mock = RingsEnvironment.init { .distantPast }
}

class RingsViewTests: XCTestCase {
  func testRingBandsTapped() {
    let store = TestStore(initialState: RingsViewState(), reducer: ringsViewReducer, environment: .mock)

    // Test tapping the concentric ring bands selects the next ring
    store.send(.concentricRingsTappedInColoredBandsArea) {
      $0.prominentRing = .session
    }
    store.send(.concentricRingsTappedInColoredBandsArea) {
      $0.prominentRing = .target
    }
    store.send(.concentricRingsTappedInColoredBandsArea) {
      $0.prominentRing = .period
    }
  }

  func testRingsPinched() {
    // TODO: Create a final pinched action and test clamping

    let store = TestStore(initialState: RingsViewState(), reducer: ringsViewReducer, environment: .mock)

    store.send(.concentricRingsPinched(scaleFactor: 0.5, whilePortrait: true)) {
      $0.layout.portrait.scaleFactorWhenFullyConcentric = 0.5
    }

    store.send(.concentricRingsPinched(scaleFactor: 0.4, whilePortrait: false)) {
      $0.layout.landscape.scaleFactorWhenFullyConcentric = 0.4
    }

    store.send(.acentricRingsPinched(scaleFactor: 0.3, whilePortrait: true)) {
      $0.layout.portrait.scaleFactorWhenFullyAcentric = 0.3
    }

    store.send(.acentricRingsPinched(scaleFactor: 0.2, whilePortrait: false)) {
      $0.layout.landscape.scaleFactorWhenFullyAcentric = 0.2
    }
  }
  
  func testRingsDragged() {
    // TODO: Create a final dragged action and test clamping

    let store = TestStore(initialState: RingsViewState(), reducer: ringsViewReducer, environment: .mock)

    store.send(.ringConcentricityDragged(concentricity: 0.5, whilePortrait: true)) {
      $0.layout.portrait.concentricity = 0.5
    }

    store.send(.ringConcentricityDragged(concentricity: 0.4, whilePortrait: false)) {
      $0.layout.landscape.concentricity = 0.4
    }
  }
  
  func testRingsTapped() {
    let store = TestStore(initialState: RingsViewState(), reducer: ringsViewReducer, environment: .mock)

    store.send(.ringsViewTapped(.period)) {
      $0.content.timeline.countdown.ticks = 0...334
    }
    
    store.send(.ringsViewTapped(.period)) {
      $0.content.timeline.countdown.ticks = 0...0
    }
  }
}
