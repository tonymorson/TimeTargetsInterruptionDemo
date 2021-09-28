import Foundation
import UIKit

public struct RingsData: Equatable {
  public var period: RingData
  public var session: RingData
  public var target: RingData

  public init(period: RingData, session: RingData, target: RingData) {
    self.period = period
    self.session = session
    self.target = target
  }

  public init() {
    period = RingData()
    session = RingData()
    target = RingData()
  }
}

public struct RingData: Equatable {
  public init(color: UIColor, trackColor: UIColor, label: RingData.LabelDetails, value: CGFloat) {
    self.color = color
    self.trackColor = trackColor
    self.label = label
    self.value = value
  }

  public struct LabelDetails: Equatable {
    public init(title: (String, String) = ("", ""), value: String = "", subtitle: String = "", caption: String = "") {
      self.title = title
      self.value = value
      self.subtitle = subtitle
      self.caption = caption
    }

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
