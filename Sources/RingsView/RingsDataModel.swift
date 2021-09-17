import Foundation
import UIKit

public struct RingsData: Equatable {
  public var period = RingData(color: .red,
                               trackColor: .systemGray4,
                               label: .init(title: ("WORK", "PERIOD"),
                                            value: "25:00",
                                            subtitle: "remaining",
                                            caption: "25 MINUTES"),
                               value: 0.2)

  public var session = RingData(color: .green,
                                trackColor: .systemGray4,
                                label: .init(title: ("MORNING", "SESSION"),
                                             value: "1 of 4",
                                             subtitle: "in progress",
                                             caption: "2 HOURS"),
                                value: 0.5)

  public var target = RingData(color: .yellow,
                               trackColor: .systemGray4,
                               label: .init(title: ("TODAY'S", "TARGET"),
                                            value: "2%",
                                            subtitle: "completed",
                                            caption: "5 HOURS"),
                               value: 0.8)

  public init() {}
}

public struct RingData: Equatable {
  public struct LabelDetails: Equatable {
    public static func == (lhs: RingData.LabelDetails, rhs: RingData.LabelDetails) -> Bool {
      lhs.title.0 == rhs.title.0
        && lhs.title.1 == rhs.title.1
        && lhs.value == rhs.value
        && lhs.subtitle == rhs.subtitle
        && lhs.caption == rhs.caption
    }

    public var title: (String, String) = ("", "")
    public var value: String = ""
    public var subtitle: String = ""
    public var caption: String = ""
  }

  public var color: UIColor
  public var trackColor: UIColor
  public var label: LabelDetails
  public var value: CGFloat
}

extension RingData {
  init() {
    color = .gray
    trackColor = .systemGray4
    label = .init()
    value = 0.0
  }
}
