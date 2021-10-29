import Foundation
import UIKit

struct AnnotatedRingsLayoutModel {
  let bounds: CGRect
  let focus: RingIdentifier
  let isAlwaysVertical: Bool
  let layout: RingsViewState.LayoutState.ConcentricityState

  let captionHeight: CGFloat
  let captionBottomPadding: CGFloat

  init(isAlwaysPortrait: Bool,
       bounds: CGRect,
       layout: RingsViewState.LayoutState.ConcentricityState,
       focus: RingIdentifier)
  {
    self.bounds = bounds
    self.focus = focus
    self.isAlwaysVertical = isAlwaysPortrait
    self.layout = layout
    
    var captionBottomPadding: CGFloat
    var captionHeight: CGFloat

    if isAlwaysPortrait {
      if bounds.isPortrait {
        let maxCircumference = concentricityDelta(max: min(bounds.width, bounds.height),
                                                  min: bounds.height / 3,
                                                  concentricity: 1 - abs(layout.concentricity))
        captionHeight = maxCircumference / 18
        captionBottomPadding = captionHeight / 4

      } else {
        let maxCircumference = concentricityDelta(max: bounds.height,
                                                  min: bounds.height / 3,
                                                  concentricity: 1 - abs(layout.concentricity))

        captionHeight = maxCircumference / 18
        captionBottomPadding = valueInConcentricRangeAt(concentricity: layout.concentricity, concentricMax: 0, acentricMin: captionHeight / 4)
      }
    } else {
      if bounds.isPortrait {
        let maxCircumference = concentricityDelta(max: bounds.width,
                                                  min: bounds.width / 3,
                                                  concentricity: 1 - abs(layout.concentricity))

        captionHeight = maxCircumference / 18
        captionBottomPadding = 0

      } else {
        let maxCircumference = concentricityDelta(max: bounds.height,
                                                  min: bounds.width / 3,
                                                  concentricity: 1 - abs(layout.concentricity))

        captionHeight = (maxCircumference / 18)
        captionBottomPadding = 0
      }
    }
    
    self.captionHeight = captionHeight
    self.captionBottomPadding = captionBottomPadding
  }

  var captionTopPadding: CGFloat { captionHeight / 2.5 }
  var captionHeightWithPadding: CGFloat {
    captionHeight + captionTopPadding + captionBottomPadding
  }

  var concentricity: CGFloat {
    layout.concentricity
  }

  var periodCenterX: CGFloat {
    isAlwaysVertical
      ? bounds.midX
      : concentricityDelta(max: bounds.midX,
                           min: bounds.midX - bounds.width / 3,
                           concentricity: 1 - concentricity)
  }

  var periodCenterY: CGFloat {
    (isAlwaysVertical
      ? concentricityDelta(max: bounds.midY,
                           min: bounds.midY - bounds.height / 3,
                           concentricity: 1 - concentricity)

      : bounds.midY) - captionHeightWithPadding / 2
  }

  var sessionCenterX: CGFloat {
    bounds.midX
  }

  var sessionCenterY: CGFloat {
    bounds.midY - captionHeightWithPadding / 2
  }

  var targetCenterX: CGFloat {
    isAlwaysVertical
      ? bounds.midX
      : bounds.width - periodCenterX
  }

  var targetCenterY: CGFloat {
    (isAlwaysVertical
      ? bounds.height - periodCenterY
      : bounds.height - periodCenterY) - captionHeightWithPadding
  }

  struct DetachedLabelConcentricityLayout {
    let bounds: CGRect
    let center: CGPoint
    let transform: CATransform3D
  }

  var detachedLabel: DetachedLabelConcentricityLayout {
    let size = CGSize(width: period.bounds.width * 0.5, height: period.bounds.height * 0.12)

    let bounds = CGRect(origin: .zero, size: size)
    let position: CGPoint
    let transform: CATransform3D

    let detachedPeriodLabelYWhenConcentric = periodCenterY - period.bounds.width / 80

    switch focus {
    case .period:
      position = CGPoint(x: periodCenterX, y: detachedPeriodLabelYWhenConcentric)
      transform = CATransform3DMakeScale(layout.scaleFactor, layout.scaleFactor, 0.5)

    case .session:
      let scaleFactor = layout.scaleFactor
      position = CGPoint(x: period.center.x,
                         y: valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                                     concentricMax: period.center.y + ((period.bounds.height / 6.55) * scaleFactor),
                                                     acentricMin: detachedPeriodLabelYWhenConcentric))

      let scale = valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                           concentricMax: 0.38,
                                           acentricMin: 1)

      transform = CATransform3DScale(CATransform3DMakeScale(scale, scale, 0.5), scaleFactor, scaleFactor, 0.5)

    case .target:
      let scaleFactor = layout.scaleFactor
      position = CGPoint(x: period.center.x,
                         y: valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                                     concentricMax: period.center.y + ((period.bounds.height / 6.55) * scaleFactor),
                                                     acentricMin: detachedPeriodLabelYWhenConcentric))

      let scale = valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                           concentricMax: 0.38,
                                           acentricMin: 1)

      transform = CATransform3DScale(CATransform3DMakeScale(scale, scale, 0.5), scaleFactor, scaleFactor, 0.5)
    }

    return .init(bounds: bounds,
                 center: position,
                 transform: transform)
  }
  
  var period: AnnotatedRingLayout {
    .init(center: CGPoint(x: periodCenterX, y: periodCenterY),
          circumference: ringCircumference,
          textOpacity: textOpacity,
          zIndex: 0,
          zoom: layout.scaleFactor)
  }

  var session: AnnotatedRingLayout {
    .init(center: CGPoint(x: sessionCenterX, y: sessionCenterY),
          circumference: ringCircumference,
          textOpacity: textOpacity,
          zIndex: abs(concentricityDelta(max: 1, min: 0, concentricity: 1 - abs(concentricity))),
          zoom: layout.scaleFactor)
  }

  var target: AnnotatedRingLayout {
    .init(center: CGPoint(x: targetCenterX, y: targetCenterY),
          circumference: ringCircumference,
          textOpacity: textOpacity,
          zIndex: abs(concentricityDelta(max: 2, min: 0, concentricity: 1 - abs(concentricity))),
          zoom: layout.scaleFactor)
  }

  var focusLayout: AnnotatedRingLayout {
    let focusKeyPath: KeyPath<Self, AnnotatedRingLayout>

    switch focus {
    case .period: focusKeyPath = \.period
    case .session: focusKeyPath = \.session
    case .target: focusKeyPath = \.target
    }

    return .init(center: self[keyPath: focusKeyPath].center,
                 circumference: self[keyPath: focusKeyPath].circumference,
                 textOpacity: 1,
                 zIndex: self[keyPath: focusKeyPath].zIndex,
                 zoom: self[keyPath: focusKeyPath].zoom)
  }

  var textOpacity: CGFloat {
    concentricityDelta(max: 1, min: 0, concentricity: abs(concentricity))
  }

  var ringCircumference: CGFloat {
    switch (isAlwaysVertical, bounds.isPortrait) {
    case (true, true):
      return concentricityDelta(max: min(bounds.width, bounds.height - captionHeightWithPadding),
                                min: (bounds.height / 3) - captionHeightWithPadding,
                                concentricity: 1 - abs(concentricity))
    case (true, false):
      return concentricityDelta(max: bounds.height - captionHeightWithPadding,
                                min: (bounds.height / 3) - captionHeightWithPadding,
                                concentricity: 1 - abs(concentricity))
    case (false, true):
      return concentricityDelta(max: bounds.width,
                                min: bounds.width / 3,
                                concentricity: 1 - abs(concentricity))
    case (false, false):
      return concentricityDelta(max: bounds.height - captionHeightWithPadding,
                                min: bounds.width / 3,
                                concentricity: 1 - abs(concentricity))
    }
  }

  var focusAlpha: CGFloat {
    valueInConcentricRangeAt(concentricity: abs(concentricity),
                             concentricMax: 1.0,
                             acentricMin: 0.0)
  }
}

struct AnnotatedRingLayout {
  let center: CGPoint
  let circumference: CGFloat
  let textOpacity: CGFloat
  let zIndex: CGFloat
  let zoom: CGFloat

  /// Returns the bounds of this view based on it's circumference.
  var bounds: CGRect {
    CGRect(origin: .zero, size: CGSize(width: circumference, height: circumference))
  }

  /// Returns a transform to use when displaying this view based on it's zoom setting.
  var transform: CATransform3D {
    CATransform3DMakeScale(zoom, zoom, 0.5)
  }
}

extension AnnotatedRingLayout {
  func apply(to ringView: AnnotatedRingView) {
    ringView.frame = bounds
    ringView.center = center
    ringView.layer.transform = transform
    ringView.zIndex = zIndex
    ringView.textAlpha = textOpacity

    ringView.ring.bounds = bounds
    ringView.text.bounds = bounds
    
    ringView.ring.center = CGPoint(x: bounds.midX, y: bounds.midY)

    let periodInset = CGFloat(bounds.width / 3.85)
    ringView.text.frame = bounds.inset(by: .init(top: periodInset, left: periodInset, bottom: periodInset, right: periodInset))

    ringView.text.center = CGPoint(x: bounds.midX, y: bounds.midY)
    ringView.caption.bounds.size.width = bounds.width // ptionHeight * 50
    ringView.caption.bounds.size.height = bounds.height / 20
    ringView.caption.center.x = bounds.midX
    ringView.caption.center.y = ringView.bounds.height + (bounds.height / 20)
  }
}

func valueInConcentricRangeAt(concentricity: CGFloat,
                              concentricMax: CGFloat,
                              acentricMin: CGFloat) -> CGFloat
{
  ((acentricMin - concentricMax) * concentricity) + concentricMax
}

private func concentricityDelta(max: CGFloat, min: CGFloat, concentricity: CGFloat) -> CGFloat {
  // clamp min to max to prevent overshoot issues
  let min = Swift.min(max, min)
  return ((max - min) * concentricity) + min
}
