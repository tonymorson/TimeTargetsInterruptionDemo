import Foundation
import UIKit

public enum AcentricLayoutMode {
  case alongLongestDimension, alwaysVertical, alwaysHorizontal
}

public struct RingsViewLayout: Equatable {
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

  public init(acentricAxis: AcentricLayoutMode,
              concentricity: CGFloat,
              focus: RingSemantic,
              scaleFactorWhenFullyAcentric: CGFloat,
              scaleFactorWhenFullyConcentric: CGFloat)
  {
    self.acentricAxis = acentricAxis
    self.concentricity = concentricity
    self.focus = focus
    self.scaleFactorWhenFullyAcentric = scaleFactorWhenFullyAcentric
    self.scaleFactorWhenFullyConcentric = scaleFactorWhenFullyConcentric
  }
}
