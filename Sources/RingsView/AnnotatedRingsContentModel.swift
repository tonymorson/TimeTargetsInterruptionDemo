import Foundation
import Timeline
import UIKit

struct AnnotatedRingsContentModel {
  var period: (String, String, String, String, String, Double, Color, Color)
  var session: (String, String, String, String, String, Double, Color, Color)
  var target: (String, String, String, String, String, Double, Color, Color)
  var focus: (String, String, String, String, String, Double, Color, Color)

  enum Color {
    case red
    case gray
    case orange
    case green
    case yellow
    case darkDarkDarkDarkGray
    case darkDarkDarkDarkDarkDarkGray
    case darkDarkGray
    case darkDarkDarkGray
  }
}

extension AnnotatedRingsContentModel {
  init(contentInfo: RingsViewState.ContentInformation) {
    let report = Report(timeline: contentInfo.content.timeline, tick: contentInfo.content.tick)
    let focusRingIdentifier = contentInfo.prominentRing

    let focus: (String, String, String, String, String, Double, Color, Color)
    let isCountingDown = report.isCountingDown

    switch focusRingIdentifier {
    case .period:
      focus = (report.periodUpper.0,
               report.periodUpper.1,
               "",
               report.periodLower,
               report.periodFooter,
               report.periodProgress,
               isCountingDown ? .red : .gray,
               isCountingDown ? .darkDarkGray : .darkDarkDarkGray)

    case .session:
      focus = (report.sessionUpper(Date()).0,
               report.sessionUpper(Date()).1,
               report.sessionHeadline,
               "",
               report.sessionFooter,
               report.sessionProgress,
               isCountingDown ? Color.green : .gray,
               isCountingDown ? .darkDarkGray : .darkDarkDarkGray)

    case .target:
      focus = (report.targetUpper.0,
               report.targetUpper.1,
               report.targetHeadline,
               "",
               report.targetFooter,
               report.targetProgress,
               isCountingDown ? .yellow : .gray,
               isCountingDown ? .darkDarkGray : .darkDarkDarkGray)
    }

    self.init(period: (report.periodUpper.0,
                       report.periodUpper.1,
                       report.periodHeadline,
                       report.periodLower,
                       report.periodFooter,
                       report.periodProgress,
                       isCountingDown ? .red : .gray,
                       isCountingDown ? .darkDarkDarkDarkGray : .darkDarkDarkDarkDarkDarkGray),

              session: (report.sessionUpper(Date()).0,
                        report.sessionUpper(Date()).1,
                        report.sessionHeadline,
                        report.sessionLower,
                        report.sessionFooter,
                        report.sessionProgress,
                        isCountingDown ? .green : .darkDarkGray,
                        isCountingDown ? .darkDarkDarkDarkGray : .darkDarkDarkDarkDarkDarkGray),

              target: (report.targetUpper.0,
                       report.targetUpper.1,
                       report.targetHeadline,
                       report.targetLower,
                       report.targetFooter,
                       report.targetProgress,
                       isCountingDown ? .yellow : .darkDarkGray,
                       isCountingDown ? .darkDarkDarkDarkGray : .darkDarkDarkDarkDarkDarkGray),

              focus: focus)
  }
}

extension AnnotatedRingsContentModel.Color {
  var color: UIColor {
    switch self {
    case .red:
      return .systemRed

    case .orange:
      return .systemOrange

    case .green:
      return .systemGreen

    case .yellow:
      return .systemYellow

    case .darkDarkDarkDarkGray:
      return .systemGray4

    case .darkDarkDarkDarkDarkDarkGray:
      return .systemGray6

    case .darkDarkGray:
      return .systemGray2

    case .darkDarkDarkGray:
      return .systemGray3

    case .gray:
      return .systemGray
    }
  }
}
