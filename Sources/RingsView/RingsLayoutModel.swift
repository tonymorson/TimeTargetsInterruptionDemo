import Foundation
import UIKit

public enum AcentricLayoutMode {
  case alongLongestDimension, alwaysVertical, alwaysHorizontal
}

public struct RingsLayout: Equatable {
  public var acentricAxis: AcentricLayoutMode
  public var concentricity: CGFloat
  public var focus: RingSemantic
  public var scaleFactorWhenFullyAcentric: CGFloat
  public var scaleFactorWhenFullyConcentric: CGFloat

  public var scaleFactor: CGFloat {
    valueInConcentricRangeAt(concentricity: abs(concentricity),
                             concentricMax: scaleFactorWhenFullyConcentric,
                             acentricMin: scaleFactorWhenFullyAcentric)
  }
}
