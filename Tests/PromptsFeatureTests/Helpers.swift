import ComposableArchitecture
import Foundation
import PromptsFeature
import XCTest

@testable import PromptsFeature

internal func annotated(title: String) -> AttributedString {
  var title = AttributedString(title)
  title.font = UIFont.systemFont(ofSize: 24, weight: .light).rounded()
  title.foregroundColor = .systemRed

  return title
}

internal func annotated(subtitle: String) -> AttributedString {
  var subtitle = AttributedString(subtitle)
  subtitle.font = UIFont.systemFont(ofSize: 18, weight: .light).rounded()
  subtitle.foregroundColor = .label

  return subtitle
}

internal extension TestStore where LocalState == PromptsView.ViewState,
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
