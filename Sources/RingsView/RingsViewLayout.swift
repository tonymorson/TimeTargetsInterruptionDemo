import Foundation
import UIKit

public enum AcentricLayoutMode {
  case alongLongestDimension, alwaysVertical, alwaysHorizontal
}

public struct RingsViewLayout: Equatable {
  public var acentricAxis: AcentricLayoutMode
  public var concentricity: CGFloat
  public var scaleFactorWhenFullyAcentric: CGFloat
  public var scaleFactorWhenFullyConcentric: CGFloat

  public var scaleFactor: CGFloat {
    valueInConcentricRangeAt(concentricity: abs(concentricity),
                             concentricMax: scaleFactorWhenFullyConcentric,
                             acentricMin: scaleFactorWhenFullyAcentric)
  }

  public init(acentricAxis: AcentricLayoutMode,
              concentricity: CGFloat,
              scaleFactorWhenFullyAcentric: CGFloat,
              scaleFactorWhenFullyConcentric: CGFloat)
  {
    self.acentricAxis = acentricAxis
    self.concentricity = concentricity
    self.scaleFactorWhenFullyAcentric = scaleFactorWhenFullyAcentric
    self.scaleFactorWhenFullyConcentric = scaleFactorWhenFullyConcentric
  }
}

public extension RingsViewLayout {
  var overReach: CGFloat {
    max(abs(concentricity), abs(scaleFactor))
  }
}
