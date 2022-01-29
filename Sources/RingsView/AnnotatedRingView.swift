import Foundation
import UIKit

final class AnnotatedRingView: UIView {
  var (ring, text, caption): (RingView, RingTextView, CaptionView)

  var canAnimateZIndex: Bool {
    set {
      ring.canAnimateZIndex = newValue
    }
    get {
      ring.canAnimateZIndex
    }
  }

  var zIndex: CGFloat {
    set {
      ring.zIndex = newValue
    }
    get {
      ring.zIndex
    }
  }

  var textAlpha: CGFloat {
    set {
      text.alpha = newValue
      caption.alpha = newValue
    }
    get {
      text.alpha
    }
  }

  override init(frame: CGRect) {
    (ring, text, caption) = (.init(frame: .zero), .init(frame: .zero), .init(frame: .zero))

    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    (ring, text, caption) = (.init(frame: .zero), .init(frame: .zero), .init(frame: .zero))

    super.init(coder: coder)
    setup()
  }

  private func setup() {
    precondition(subviews.isEmpty, "Setup improperly called. Call early and once on initialization.")

    addSubview(ring)
    addSubview(text)
    addSubview(caption)
  }
}

final class CaptionView: UIView {
  var text: String = "" {
    didSet {
      guard oldValue != text else { return }
      layer.setNeedsDisplay()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .clear
    setupLayer()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    backgroundColor = .clear
    setupLayer()
  }

  override func draw(_ layer: CALayer, in ctx: CGContext) {
    super.draw(layer, in: ctx)
    UIGraphicsPushContext(ctx)
    defer { UIGraphicsPopContext() }
    drawCaption(in: ctx)
  }

  private func drawCaption(in ctx: CGContext) {
    let smallFontSize = CGFloat(bounds.height)
    let smallFont = UIFont(name: "HelveticaNeue-Light", size: smallFontSize) ??
      .systemFont(ofSize: smallFontSize, weight: .thin)

    let captionAttributes = [
      NSAttributedString.Key.font: smallFont,
      NSAttributedString.Key.foregroundColor: UIColor.systemOrange,
    ]

    let caption = NSAttributedString(string: text, attributes: captionAttributes)
    let captionBounds = stringBounds(string: caption, ctx: ctx)
    caption.draw(at: CGPoint(x: (bounds.width / 2) - (captionBounds.width / 2),
                             y: 0))
  }

  private func setupLayer() {
    layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    layer.contentsScale = UIScreen.main.scale * 3
  }
}

final class RingTextView: UIView {
  var color: UIColor = .label {
    didSet {
      if oldValue != color {
        layer.setNeedsDisplay()
      }
    }
  }

  var content: Content = .init() {
    didSet {
      // Don't check for oldValue here... if you do
      // you will break changing theme updates from
      // dark to light mode...
      layer.setNeedsDisplay()
    }
  }

  struct Content: Equatable {
    var titleLine1: String = ""
    var titleLine2: String = ""
    var value: String = ""
    var subtitle: String = ""
    var caption: String = ""
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .clear
    setupLayer()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    backgroundColor = .clear
    setupLayer()
  }

  override func draw(_ layer: CALayer, in ctx: CGContext) {
    super.draw(layer, in: ctx)
    UIGraphicsPushContext(ctx)
    defer { UIGraphicsPopContext() }
    drawInnerRingText(in: ctx)
  }

  private func drawInnerRingText(in ctx: CGContext) {
    let headlineFontSize = CGFloat(bounds.width) / 4.0
    let font = UIFont(name: "HelveticaNeue-Light", size: headlineFontSize) ??
      .monospacedSystemFont(ofSize: headlineFontSize, weight: .ultraLight)

    let smallFontSize = CGFloat(bounds.width) / 4.25 / 2
    let smallFont = UIFont(name: "HelveticaNeue-Light", size: smallFontSize) ??
      .systemFont(ofSize: smallFontSize, weight: .thin)

    let smallLabelAttributes = [NSAttributedString.Key.font: smallFont, NSAttributedString.Key.foregroundColor: color.resolvedColor(with: .init(userInterfaceStyle: traitCollection.userInterfaceStyle))]

    let largeLabelAttributes = [NSAttributedString.Key.font: font,
                                NSAttributedString.Key.foregroundColor: color.resolvedColor(with: .init(userInterfaceStyle: traitCollection.userInterfaceStyle))]

    let valueDescription = NSAttributedString(string: content.value, attributes: largeLabelAttributes)
    let valueBounds = stringBounds(string: valueDescription, ctx: ctx)
    valueDescription.draw(at: CGPoint(x: (bounds.width / 2) - valueBounds.width / 2,
                                      y: (bounds.height / 2) - (valueBounds.height / 1.05)))

    let ringDescription1 = NSAttributedString(string: content.titleLine1, attributes: smallLabelAttributes)
    let ringDescription2 = NSAttributedString(string: content.titleLine2, attributes: smallLabelAttributes)

    let ringDescription1Dimensions = CTLineCreateWithAttributedString(ringDescription1)
    let ringDescripion2Dimensions = CTLineCreateWithAttributedString(ringDescription2)

    let stringRect2 = CTLineGetImageBounds(ringDescription1Dimensions, ctx)
    let stringRect3 = CTLineGetImageBounds(ringDescripion2Dimensions, ctx)

    let topLegendX = CGFloat.zero
    ringDescription1.draw(at: CGPoint(x: (bounds.width / 2) - stringRect2.width / 2,
                                      y: topLegendX))

    ringDescription2.draw(at: CGPoint(x: (bounds.width / 2) - stringRect3.width / 2, y: topLegendX + (stringRect2.height * 1.3)))

    let subtitle = NSAttributedString(string: content.subtitle, attributes: smallLabelAttributes)
    let subtitleBounds = stringBounds(string: subtitle, ctx: ctx)
    subtitle.draw(at: CGPoint(x: (bounds.width / 2) - subtitleBounds.width / 2, y: bounds.height - (bounds.height / 3.85)))
  }

  private func setupLayer() {
    layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    layer.contentsScale = UIScreen.main.scale * 3
  }
}
