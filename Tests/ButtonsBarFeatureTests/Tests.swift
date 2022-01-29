// import ComposableArchitecture
// import Foundation
// import XCTest
//
// @testable import ButtonsBarFeature
//
// class ButtonsBarFeatureTests: XCTestCase {
//  func testButtons() {
//    let initialState = ButtonsBarState(isShowingTabs: false, selectedTab: .today)
//    let store = TestStore(initialState: initialState,
//                          reducer: buttonsBarReducer,
//                          environment: ())
//
//    store.send(.buttonTapped(.settings))
//
//    store.send(.buttonTapped(.tabsModeOn)) {
//      $0.isShowingTabs = true
//    }
//
//    store.send(.buttonTapped(.tabsModeOff)) {
//      $0.isShowingTabs = false
//    }
//
//    store.send(.buttonTapped(.tabsModeOn)) {
//      $0.isShowingTabs = true
//    }
//
//    store.send(.buttonTapped(.showTab(.tasks))) {
//      $0.selectedTab = .tasks
//    }
//
//    store.send(.buttonTapped(.showTab(.charts))) {
//      $0.selectedTab = .charts
//    }
//
//    store.send(.buttonTapped(.showTab(.today))) {
//      $0.selectedTab = .today
//    }
//  }
// }
