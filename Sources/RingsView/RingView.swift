import Foundation
import UIKit

final class RingView: UIView {
  var canAnimateZIndex: Bool {
    set { ringLayer.canAnimateZIndex = newValue }
    get { ringLayer.canAnimateZIndex }
  }

  var color: UIColor {
    set { ringLayer.color = newValue.cgColor }
    get { UIColor(cgColor: ringLayer.color) }
  }

  var innerRadius: CGFloat {
    ringLayer.innerRadius
  }

  var outerRadius: CGFloat {
    ringLayer.outerRadius
  }

  var value: CGFloat {
    set { ringLayer.value = newValue }
    get { ringLayer.value }
  }

  var zIndex: CGFloat {
    set { ringLayer.zIndex = newValue }
    get { ringLayer.zIndex }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .clear
    setupRingLayer()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    backgroundColor = .clear
    setupRingLayer()
  }

  override public class var layerClass: AnyClass {
    RingLayer.self
  }

  override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
      layer.setNeedsLayout()
    }
  }

  private var ringLayer: RingLayer {
    layer as! RingLayer
  }

  private func setupRingLayer() {
    ringLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    ringLayer.contentsScale = UIScreen.main.scale
  }
}

private final class RingLayer: CALayer {
  @NSManaged var color: CGColor
  @NSManaged var value: CGFloat
  @NSManaged var zIndex: CGFloat

  var canAnimateZIndex: Bool = true

  var lineWidth: CGFloat {
    let dimension = (min(bounds.width, bounds.height) - 0)

    return dimension / 15
  }

  var radius: CGFloat {
    let dimension = (min(bounds.width, bounds.height) - 0)
    let radiusIn: CGFloat = (dimension / 2) - (lineWidth / 2)
    let gapBetweenRings = (lineWidth + (bounds.width / 340))

    return radiusIn - (gapBetweenRings * zIndex)
  }

  var innerRadius: CGFloat {
    radius - (lineWidth / 2)
  }

  var outerRadius: CGFloat {
    radius + (lineWidth / 2)
  }

  override init() {
    super.init()
  }

  override init(layer: Any) {
    guard let layer = layer as? RingLayer else { fatalError("unable to copy layer") }

    super.init(layer: layer)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func action(forKey event: String) -> CAAction? {
    switch event {
    case "zIndex":
      guard canAnimateZIndex
      else { return super.action(forKey: event) }

      let action = CASpringAnimation(keyPath: "zIndex")
      action.damping = 25
      action.stiffness = 300
      action.initialVelocity = 10
      action.mass = 0.5
      action.fromValue = presentation()?.value(forKey: "zIndex")
      action.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
      action.duration = action.settlingDuration

      return action

    case "color":
      let action = CABasicAnimation(keyPath: "color")
      action.fromValue = presentation()?.value(forKey: "color")
      action.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
      action.duration = 0.20

      return action

    case "value":
      let action = CABasicAnimation(keyPath: "value")
      action.fromValue = presentation()?.value(forKey: "value")
      action.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
      action.duration = 0.20

      return action

    default:

      return super.action(forKey: event)
    }
  }

  override func draw(in ctx: CGContext) {
    super.draw(in: ctx)

    UIGraphicsPushContext(ctx)
    defer { UIGraphicsPopContext() }

    drawRing(in: ctx)
  }

  /**
   Draws the ring for the view.
   Sets path properties according to how the user has decided to customize the view.
   */
  private func drawRing(in ctx: CGContext) {
    let verticalOffset = bounds.midX - bounds.midY
    let center = CGPoint(x: bounds.midX, y: bounds.midY + verticalOffset)
    let innerPath = UIBezierPath(arcCenter: center,
                                 radius: radius,
                                 startAngle: startAngle,
                                 endAngle: toEndAngleFor(value: value),
                                 clockwise: true)

    // Draw path
    ctx.setLineWidth(lineWidth)
    ctx.setLineJoin(.round)
    ctx.setLineCap(CGLineCap.round)
    ctx.setStrokeColor(color)
    ctx.addPath(innerPath.cgPath)

    ctx.drawPath(using: .stroke)
  }

  override class func needsDisplay(forKey key: String) -> Bool {
    if
      key == "color"
      || key == "value"
      || key == "zIndex"
    {
      return true
    } else {
      return super.needsDisplay(forKey: key)
    }
  }
}

/// **
// A private extension to CGFloat in order to provide simple
// conversion from degrees to radians, used when drawing the rings.
// */
private extension CGFloat {
  var rads: CGFloat { self * CGFloat.pi / 180 }
}

private let startAngle = CGFloat(-90).rads
func toEndAngleFor(value: CGFloat) -> CGFloat {
  (value * 360.0).rads + startAngle
}
