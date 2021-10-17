import Foundation
import UIKit

final class CompositeRingView: UIView {
  var details = RingData() {
    didSet {
      ring.color = details.color
      ring.value = details.value
      text.content = details.label
      caption.text = details.label.caption
    }
  }

  var canAnimateZIndex: Bool {
    set {
      ring.canAnimateZIndex = newValue
    }
    get {
      ring.canAnimateZIndex
    }
  }

  var ring = RingView(frame: .zero)
  var text = RingTextView(frame: .zero)
  var caption = CaptionView(frame: .zero)

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
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

  func setup() {
    addSubview(ring)
    addSubview(text)
    addSubview(caption)

    ring.color = UIColor.systemGray

    ring.value = 0.0

    text.content = .init(title: ("", ""), value: "", subtitle: "", caption: "")
    caption.text = ""
  }

  func apply(layout: RingConcentricityLayout) {
    frame = layout.bounds
    center = layout.center
    layer.transform = layout.transform
    zIndex = layout.zIndex
    textAlpha = layout.textOpacity

    ring.bounds = bounds
    text.bounds = bounds

    ring.center = CGPoint(x: bounds.midX, y: bounds.midY)

    let periodInset = CGFloat(bounds.width / 3.85)
    text.frame = bounds.inset(by: .init(top: periodInset, left: periodInset, bottom: periodInset, right: periodInset))

    text.center = CGPoint(x: bounds.midX, y: bounds.midY)
    caption.bounds.size.width = layout.bounds.width // ptionHeight * 50
    caption.bounds.size.height = layout.bounds.height / 20
    caption.center.x = bounds.midX
    caption.center.y = ring.bounds.height + (layout.bounds.height / 20)
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

  private func setupLayer() {
    layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    layer.contentsScale = UIScreen.main.scale * 3
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
}
