import Foundation
import UIKit

public struct RingsViewState: Equatable {
  public var content: RingsData
  public var layout: RingsViewLayout
  public var prominentRing: RingIdentifier

  public init(content: RingsData, layout: RingsViewLayout, prominentRing: RingIdentifier) {
    self.content = content
    self.layout = layout
    self.prominentRing = prominentRing
  }
}

public enum RingIdentifier: Int { case period, session, target }

public enum RingsViewAction: Equatable {
  case acentricRingsPinched(scaleFactor: CGFloat)
  case concentricRingsPinched(scaleFactor: CGFloat)
  case concentricRingsTappedInColoredBandsArea
  case ringConcentricityDragged(concentricity: CGFloat)
  case ringsViewTapped(RingIdentifier?)
}

public struct RingsViewEnvironment {
  var isPortrait: () -> Bool

  public init(isPortrait: @escaping () -> Bool) {
    self.isPortrait = isPortrait
  }
}

// public let ringsViewEnvironment = RingsViewEnvironment(isPortrait: { true } )

public func ringsViewReducer(state: inout RingsViewState, action: RingsViewAction) {
  switch action {
  case let .acentricRingsPinched(scaleFactor: scaleFactor):
    state.layout.scaleFactorWhenFullyAcentric = scaleFactor

  case let .concentricRingsPinched(scaleFactor: scaleFactor):
    state.layout.scaleFactorWhenFullyConcentric = scaleFactor

  case .concentricRingsTappedInColoredBandsArea:
    switch state.prominentRing {
    case .period: state.prominentRing = .session
    case .session: state.prominentRing = .target
    case .target: state.prominentRing = .period
    }

  case let .ringConcentricityDragged(newValue):
    state.layout.concentricity = newValue

  case .ringsViewTapped(.some):
    if state.content.period.color == .systemGray2 || state.content.period.color == .lightGray {
      state.content.period.color = .systemRed
      state.content.session.color = .systemGreen
      state.content.target.color = .systemYellow

      state.content.period.trackColor = .systemGray4
      state.content.session.trackColor = .systemGray4
      state.content.target.trackColor = .systemGray4

    } else {
      state.content.period.color = .systemGray2
      state.content.session.color = .systemGray2
      state.content.target.color = .systemGray2

      state.content.period.trackColor = UIColor.systemGray5
      state.content.session.trackColor = .systemGray5
      state.content.target.trackColor = .systemGray5
    }

  case .ringsViewTapped(.none):
    break
  }
}

public final class RingsView: UIView {
  @Published public var sentActions: RingsViewAction?

  public var state = RingsViewState() {
    didSet { update(from: oldValue, to: state) }
  }

  private let periodTrack = RingView(frame: .zero)
  private let sessionTrack = RingView(frame: .zero)
  private let targetTrack = RingView(frame: .zero)
  private let focusTrack = RingView(frame: .zero)

  private let period = CompositeRingView(frame: .zero)
  private let session = CompositeRingView(frame: .zero)
  private let target = CompositeRingView(frame: .zero)
  private let focus = CompositeRingView(frame: .zero)
  private let detachedPeriodLabel = LabelView(frame: .zero)

  private enum Direction { case vertical, horizontal }
  private var layoutDirection: Direction {
    switch state.layout.acentricAxis {
    case .alwaysVertical: return .vertical
    case .alwaysHorizontal: return .horizontal
    case .alongLongestDimension where isPortrait: return .vertical
    case .alongLongestDimension where isLandscape: return .horizontal
    case .alongLongestDimension: fatalError()
    }
  }

  private var canAnimateZIndex: Bool = true {
    didSet {
      periodTrack.canAnimateZIndex = canAnimateZIndex
      sessionTrack.canAnimateZIndex = canAnimateZIndex
      targetTrack.canAnimateZIndex = canAnimateZIndex
      focusTrack.canAnimateZIndex = canAnimateZIndex

      period.canAnimateZIndex = canAnimateZIndex
      session.canAnimateZIndex = canAnimateZIndex
      target.canAnimateZIndex = canAnimateZIndex
      focus.canAnimateZIndex = canAnimateZIndex
    }
  }

  public init(state: RingsViewState) {
    super.init(frame: .zero)

    self.state = state

    setup()
  }

  override init(frame _: CGRect) {
    fatalError()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError()
  }

  override public func layoutSubviews() {
    super.layoutSubviews()

    apply(concentricLayout: ConcentricLayout(bounds: bounds,
                                             layout: state.layout,
                                             focus: state.prominentRing))
  }

  override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
      updateRing(details: state.content)
    }

    super.traitCollectionDidChange(previousTraitCollection)
  }

  private let pan = UIPanGestureRecognizer()
  private let pinch = UIPinchGestureRecognizer()
  private let tap = UITapGestureRecognizer()

  private func setup() {
    savedRingScaleFactor = 0.0

    addSubview(periodTrack)
    addSubview(sessionTrack)
    addSubview(targetTrack)
    addSubview(focusTrack)

    periodTrack.value = 1.0
    sessionTrack.value = 1.0
    targetTrack.value = 1.0
    focusTrack.value = 1.0

    addSubview(target)
    addSubview(session)
    addSubview(period)
    addSubview(focus)
    addSubview(detachedPeriodLabel)

    addGestureRecognizer(pan)
    pan.addTarget(self, action: #selector(onPan))

    addGestureRecognizer(pinch)
    pinch.addTarget(self, action: #selector(onPinch))

    addGestureRecognizer(tap)
    tap.addTarget(self, action: #selector(onTap))

    tap.delegate = self
    pinch.delegate = self
    pan.delegate = self

    backgroundColor = .systemBackground

    updateRing(details: state.content)
  }

  private func update(from: RingsViewState, to: RingsViewState) {
    if from.content != to.content {
      updateRing(details: to.content)
    }

    if from.layout != to.layout || from.prominentRing != to.prominentRing {
      apply(concentricLayout: ConcentricLayout(bounds: bounds, layout: to.layout, focus: to.prominentRing))

      if from.prominentRing != to.prominentRing {
        updateProminentRingDetails()
      }
    }
  }

  private func updateRing(details: RingsData) {
    var modified = details.period
    modified.label.value = ""

    periodTrack.color = details.period.trackColor
    sessionTrack.color = details.session.trackColor
    targetTrack.color = details.target.trackColor

    period.details = modified
    session.details = details.session
    target.details = details.target

    updateProminentRingDetails()

    detachedPeriodLabel.text = details.period.label.value
  }

  private func updateProminentRingDetails() {
    focus.details = self[keyPath: focusRingKeyPath].details
    focusTrack.color = focus.details.color.darker!

    if focus.details.color == UIColor.systemGray2 {
      switch state.prominentRing {
      case .period: focus.details.color = .systemRed.slightyDarker!
      case .session: focus.details.color = .systemGreen.slightyDarker!
      case .target: focus.details.color = .systemYellow.slightyDarker!
      }
    }

//    let shadowRadius = bounds.width / 85

//    focusTrack.layer.shadowColor = self[keyPath: focusRingKeyPath].color.darker!.darker!.cgColor
//    focusTrack.layer.shadowOffset = CGSize(width: 0, height: shadowRadius * 1.55)
//    focusTrack.layer.shadowRadius = shadowRadius
//    focusTrack.layer.shadowOpacity = 0.45
//
//    focus.layer.shadowColor = self[keyPath: focusRingKeyPath].color.darker?.darker?.cgColor
//      ?? UIColor.systemGray2.cgColor
//    focus.layer.shadowOffset = .zero // CGSize(width: shadowRadius * 1.5, height: shadowRadius * 1.05)
//    focus.layer.shadowRadius = shadowRadius * 5
//    focus.layer.shadowOpacity = 0.95

    switch state.prominentRing {
    case .period:
      focus.text.content.subtitle = period.text.content.subtitle
    case .session:
      focus.text.content.subtitle = ""
    case .target:
      focus.text.content.subtitle = ""
    }
  }

  @objc private func onTap(gesture: UITapGestureRecognizer) {
    if let ring = ringHitTest(for: gesture) {
      sentActions = .ringsViewTapped(ring)
      return
    }

    if focus.point(inside: gesture.location(in: focus), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let focusInnerRadius = target.ring.innerRadius
      let periodOuterRadius = period.ring.outerRadius
      let distance = distanceBetween(point: gesture.location(in: focus), and: midPoint)

      if distance >= focusInnerRadius, distance < periodOuterRadius {
        detachedLabelAnimation {
          self.sentActions = .concentricRingsTappedInColoredBandsArea
        }

        return
      }
    }

    sentActions = .ringsViewTapped(nil)
  }

  private func ringHitTest(for gesture: UITapGestureRecognizer) -> RingIdentifier? {
    if focus.point(inside: gesture.location(in: period), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let focusInnerRadius = target.ring.innerRadius
      let periodOuterRadius = period.ring.outerRadius
      let distance = distanceBetween(point: gesture.location(in: period), and: midPoint)

      if distance >= focusInnerRadius, distance < periodOuterRadius {
        return nil
      }

      if distance < focusInnerRadius {
        switch state.prominentRing {
        case .period: return .period
        case .session: return .period
        case .target: return .target
        }
      }
    } else if period.point(inside: gesture.location(in: period), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let periodInnerRadius = period.ring.innerRadius
      let distance = distanceBetween(point: gesture.location(in: period), and: midPoint)

      if distance < periodInnerRadius {
        return .period
      }
    } else if session.point(inside: gesture.location(in: session), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let sessionInnerRadius = session.ring.innerRadius
      let distance = distanceBetween(point: gesture.location(in: session), and: midPoint)

      if distance < sessionInnerRadius {
        return .session
      }
    } else if target.point(inside: gesture.location(in: target), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let targetInnerRadius = target.ring.innerRadius
      let distance = distanceBetween(point: gesture.location(in: target), and: midPoint)

      if distance < targetInnerRadius {
        return .target
      }
    }

    return nil
  }

  private var savedRingScaleFactor: CGFloat = .zero
  private var savedLayoutKeyPath: WritableKeyPath<RingsViewState, RingsViewLayout>!
  @objc private func onPinch(gesture: UIPinchGestureRecognizer) {
    switch gesture.state {
    case .began:
      savedLayoutKeyPath = \RingsViewState.layout
      savedRingScaleFactor = state[keyPath: savedLayoutKeyPath].scaleFactor

      let newValue = restrain(value: gesture.scale * savedRingScaleFactor, in: 0.55 ... 0.999999, factor: 2.2)

      sentActions = state[keyPath: savedLayoutKeyPath].concentricity == 0.0
        ? .concentricRingsPinched(scaleFactor: newValue)
        : .acentricRingsPinched(scaleFactor: newValue)

    case .changed:
      let newValue = restrain(value: gesture.scale * savedRingScaleFactor, in: 0.55 ... 0.999999, factor: 2.2)

      sentActions = state[keyPath: savedLayoutKeyPath].concentricity == 0.0
        ? .concentricRingsPinched(scaleFactor: newValue)
        : .acentricRingsPinched(scaleFactor: newValue)

    case .ended:
      let pinchScale = restrain(value: gesture.scale * savedRingScaleFactor, in: 0.55 ... 0.999999, factor: 2.2)
      let clampedScale = max(0.55, min(1.0, pinchScale))

      UIView.animate(withDuration: 0.45,
                     delay: 0.0,
                     usingSpringWithDamping: 0.5,
                     initialSpringVelocity: 0.5,
                     options: [.allowUserInteraction]) {
        self.sentActions = self.state[keyPath: self.savedLayoutKeyPath].concentricity == 0.0
          ? .concentricRingsPinched(scaleFactor: clampedScale)
          : .acentricRingsPinched(scaleFactor: clampedScale)
      }

    case .possible:
      break

    default:
      state[keyPath: savedLayoutKeyPath].scaleFactorWhenFullyConcentric = savedRingScaleFactor
    }
  }

  private var panStart: (RingIdentifier, CGPoint)?
  private var panStartConcentricity: CGFloat = 0.0
  @objc private func onPan(gesture: UIPanGestureRecognizer) {
    let dragDirectionModifier: CGFloat

    switch panStart {
    case let .some(value) where value.0 == .period:
      dragDirectionModifier = 1

    case let .some(value) where value.0 == .session && layoutDirection == .vertical:
      dragDirectionModifier = value.1.y - 20 > bounds.height / 2 ? -1 : 1

    case let .some(value) where value.0 == .session && layoutDirection == .horizontal:
      dragDirectionModifier = value.1.x > bounds.width / 2 ? -1 : 1

    case let .some(value) where value.0 == .target:
      dragDirectionModifier = -1

    default:
      panStart = nil
      return
    }

    let dimension = isPortrait
      ? bounds.height / 3
      : bounds.width / 3

    switch gesture.state {
    case .possible:
      break

    case .began:
      savedLayoutKeyPath = \RingsViewState.layout

      panStart?.1 = gesture.location(in: self)
      canAnimateZIndex = false
      panStartConcentricity = state[keyPath: savedLayoutKeyPath].concentricity

      let gestureKeyPath = state[keyPath: savedLayoutKeyPath].dragGestureKeyPathFor(bounds: bounds)
      let dragAmount = -gesture.translation(in: self)[keyPath: gestureKeyPath] * dragDirectionModifier
      let concentricDelta = dragAmount / dimension
      let concentricity = concentricDelta + panStartConcentricity

      sentActions = .ringConcentricityDragged(concentricity: concentricity)

    case .changed:
      let gestureKeyPath = state[keyPath: savedLayoutKeyPath].dragGestureKeyPathFor(bounds: bounds)
      let dragAmount = -gesture.translation(in: self)[keyPath: gestureKeyPath] * dragDirectionModifier
      let concentricDelta = dragAmount / dimension
      let concentricity = restrain(value: concentricDelta + panStartConcentricity,
                                   in: -1.0 ... 1.0,
                                   factor: 118.4)

      sentActions = .ringConcentricityDragged(concentricity: concentricity)

    case .ended:
      canAnimateZIndex = true
      panStart = nil

      let gestureKeyPath = state.layout.dragGestureKeyPathFor(bounds: bounds)
      let dragAmount = -gesture.translation(in: self)[keyPath: gestureKeyPath]

      let velocity = gesture.velocity(in: self)
      let projectedTranslation = UIGestureRecognizer.project(isPortrait ? velocity.y : velocity.x, onto: -dragAmount) * dragDirectionModifier

      let concentricDelta = -projectedTranslation / dimension
      let concentricity = concentricDelta + panStartConcentricity
      let restingConcentricity = max(-1, min(1, concentricity.rounded()))

      let damping: CGFloat
      let springVelocity: CGFloat

      let dimesionalVelocity = abs(isPortrait ? velocity.y : velocity.x)

      switch dimesionalVelocity {
      case ...200:
        damping = 0.77
        springVelocity = 0.5
      case 201 ... 3000:
        damping = 0.70
        springVelocity = 15.0
      case 3001 ... 6000:
        damping = 0.65
        springVelocity = 30.00
      case 6001...:
        damping = 0.55
        springVelocity = 40.00
      default:
        damping = 0.35
        springVelocity = 0.40
      }

      UIView.animate(withDuration: 0.35,
                     delay: 0.0,
                     usingSpringWithDamping: damping,
                     initialSpringVelocity: springVelocity,
                     options: [.allowUserInteraction, .beginFromCurrentState]) {
        self.sentActions = .ringConcentricityDragged(concentricity: restingConcentricity)
      }
    case .cancelled:
      break
    case .failed:
      break
    @unknown default:
      break
    }
  }

  private var focusRingKeyPath: KeyPath<RingsView, CompositeRingView> {
    switch state.prominentRing {
    case .period:
      return \.period
    case .session:
      return \.session
    case .target:
      return \.target
    }
  }

  private func apply(concentricLayout: ConcentricLayout) {
    assertMainThread()

    period.apply(layout: concentricLayout.period)
    session.apply(layout: concentricLayout.session)
    target.apply(layout: concentricLayout.target)
    focus.apply(layout: concentricLayout.focusLayout)

    periodTrack.bounds = period.bounds
    periodTrack.center = period.center
    periodTrack.zIndex = period.zIndex
    periodTrack.layer.transform = concentricLayout.period.transform

    sessionTrack.bounds = session.bounds
    sessionTrack.center = session.center
    sessionTrack.zIndex = session.zIndex
    sessionTrack.layer.transform = concentricLayout.period.transform

    targetTrack.bounds = target.bounds
    targetTrack.center = target.center
    targetTrack.zIndex = target.zIndex
    targetTrack.layer.transform = concentricLayout.period.transform

    focusTrack.bounds = focus.bounds
    focusTrack.center = focus.center
    focusTrack.zIndex = focus.zIndex
    focusTrack.layer.transform = focus.layer.transform

    let detachedLabelLayout = concentricLayout.detachedLabel
    detachedPeriodLabel.bounds = detachedLabelLayout.bounds
    detachedPeriodLabel.center = detachedLabelLayout.center
    detachedPeriodLabel.layer.transform = detachedLabelLayout.transform

    focus.alpha = concentricLayout.focusAlpha
    focusTrack.alpha = concentricLayout.focusAlpha
  }

  override public var bounds: CGRect {
    didSet {
      assertMainThread()
      guard oldValue != bounds else { return }

      forceRedraw()
    }
  }
}

private extension RingsView {
  func forceRedraw() {
    periodTrack.layer.setNeedsDisplay()
    sessionTrack.layer.setNeedsDisplay()
    targetTrack.layer.setNeedsDisplay()

    period.ring.layer.setNeedsDisplay()
    session.ring.layer.setNeedsDisplay()
    target.ring.layer.setNeedsDisplay()

    period.text.layer.setNeedsDisplay()
    session.text.layer.setNeedsDisplay()
    target.text.layer.setNeedsDisplay()

    period.caption.layer.setNeedsDisplay()
    session.caption.layer.setNeedsDisplay()
    target.caption.layer.setNeedsDisplay()
  }
}

extension RingsView: UIGestureRecognizerDelegate {
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer == pan, panStart == nil {
      guard let ring = testRing(for: touch) else { return false }
      panStart = (ring, touch.location(in: self))
    }

    return true
  }

  private func testRing(for touch: UITouch) -> RingIdentifier? {
    if period.point(inside: touch.location(in: period), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let periodOuterRadius = period.ring.outerRadius
      let distance = distanceBetween(point: touch.location(in: period), and: midPoint)

      if distance < periodOuterRadius {
        return .period
      }
    } else if session.point(inside: touch.location(in: session), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let sessionOuterRadius = session.ring.outerRadius
      let distance = distanceBetween(point: touch.location(in: session), and: midPoint)

      if distance < sessionOuterRadius {
        return .session
      }
    } else if target.point(inside: touch.location(in: target), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let targetOuterRadius = target.ring.outerRadius
      let distance = distanceBetween(point: touch.location(in: target), and: midPoint)

      if distance < targetOuterRadius {
        return .target
      }
    }
    return nil
  }
}

struct RingConcentricityLayout {
  let center: CGPoint
  let circumference: CGFloat
  let textOpacity: CGFloat
  let zIndex: CGFloat
  let zoom: CGFloat

  var bounds: CGRect {
    CGRect(origin: .zero, size: CGSize(width: circumference, height: circumference))
  }

  var transform: CATransform3D {
    CATransform3DMakeScale(zoom, zoom, 0.5)
  }
}

func concentricityDelta(max: CGFloat, min: CGFloat, concentricity: CGFloat) -> CGFloat {
  // clamp min to max to prevent overshoot issues
  let min = Swift.min(max, min)
  return ((max - min) * concentricity) + min
}

private extension UIGestureRecognizer {
  static func project(_ velocity: CGFloat,
                      onto position: CGFloat,
                      decelerationRate: UIScrollView.DecelerationRate = .normal) -> CGFloat
  {
    position - 0.001 * velocity / log(decelerationRate.rawValue)
  }
}

func valueInConcentricRangeAt(concentricity: CGFloat,
                              concentricMax: CGFloat,
                              acentricMin: CGFloat) -> CGFloat
{
  ((acentricMin - concentricMax) * concentricity) + concentricMax
}

func distanceBetween(point: CGPoint, and otherPoint: CGPoint) -> CGFloat {
  sqrt(pow(otherPoint.x - point.x, 2) + pow(otherPoint.y - point.y, 2))
}

private struct ConcentricLayout {
  let bounds: CGRect
  let focus: RingIdentifier
  let vertical: Bool
  let layout: RingsViewLayout

  var captionHeight: CGFloat = 152
  var captionTopPadding: CGFloat { captionHeight / 2.5 }
  var captionBottomPadding: CGFloat = 0

  var captionHeightWithPadding: CGFloat {
    captionHeight + captionTopPadding + captionBottomPadding
  }

  var concentricity: CGFloat {
    layout.concentricity
  }

  var periodCenterX: CGFloat {
    vertical
      ? bounds.midX
      : concentricityDelta(max: bounds.midX,
                           min: bounds.midX - bounds.width / 3,
                           concentricity: 1 - concentricity)
  }

  var periodCenterY: CGFloat {
    (vertical
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
    vertical
      ? bounds.midX
      : bounds.width - periodCenterX
  }

  var targetCenterY: CGFloat {
    (vertical
      ? bounds.height - periodCenterY
      : bounds.height - periodCenterY) - captionHeightWithPadding
  }

  var period: RingConcentricityLayout {
    .init(center: CGPoint(x: periodCenterX, y: periodCenterY),
          circumference: ringCircumference,
          textOpacity: textOpacity,
          zIndex: 0,
          zoom: layout.scaleFactor)
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
      position = CGPoint(x: period.center.x,
                         y: valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                                     concentricMax: period.center.y + (period.bounds.height / 6.55),
                                                     acentricMin: detachedPeriodLabelYWhenConcentric))

      let scale = valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                           concentricMax: 0.38,
                                           acentricMin: layout.scaleFactor)
      transform = CATransform3DScale(CATransform3DMakeScale(scale, scale, 0.5),
                                     layout.scaleFactor,
                                     layout.scaleFactor,
                                     0.5)

    case .target:
      position = CGPoint(x: period.center.x,
                         y: valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                                     concentricMax: period.center.y + (period.bounds.height / 6.55),
                                                     acentricMin: detachedPeriodLabelYWhenConcentric))

      let scale = valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                           concentricMax: 0.38,
                                           acentricMin: layout.scaleFactor)

      transform = CATransform3DScale(CATransform3DMakeScale(scale, scale, 0.5), layout.scaleFactor, layout.scaleFactor, 0.5)
    }

    return .init(bounds: bounds,
                 center: position,
                 transform: transform)
  }

  var session: RingConcentricityLayout {
    .init(center: CGPoint(x: sessionCenterX, y: sessionCenterY),
          circumference: ringCircumference,
          textOpacity: textOpacity,
          zIndex: abs(concentricityDelta(max: 1, min: 0, concentricity: 1 - abs(concentricity))),
          zoom: layout.scaleFactor)
  }

  var target: RingConcentricityLayout {
    .init(center: CGPoint(x: targetCenterX, y: targetCenterY),
          circumference: ringCircumference,
          textOpacity: textOpacity,
          zIndex: abs(concentricityDelta(max: 2, min: 0, concentricity: 1 - abs(concentricity))),
          zoom: layout.scaleFactor)
  }

  var focusLayout: RingConcentricityLayout {
    let focusKeyPath: KeyPath<Self, RingConcentricityLayout>

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
    switch (vertical, bounds.isPortrait) {
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

  init(isAlwaysPortrait: Bool, bounds: CGRect, layout: RingsViewLayout, focus: RingIdentifier) {
    vertical = isAlwaysPortrait
    self.bounds = bounds
    self.layout = layout
    self.focus = focus

    if isAlwaysPortrait {
      if bounds.isPortrait {
        let maxCircumference = concentricityDelta(max: min(bounds.width, bounds.height),
                                                  min: bounds.height / 3,
                                                  concentricity: 1 - abs(concentricity))
        captionHeight = maxCircumference / 18
        captionBottomPadding = captionHeight / 4

      } else {
        let maxCircumference = concentricityDelta(max: bounds.height,
                                                  min: bounds.height / 3,
                                                  concentricity: 1 - abs(concentricity))

        captionHeight = maxCircumference / 18
        captionBottomPadding = valueInConcentricRangeAt(concentricity: concentricity, concentricMax: 0, acentricMin: captionHeight / 4)
      }
    } else {
      if bounds.isPortrait {
        let maxCircumference = concentricityDelta(max: bounds.width,
                                                  min: bounds.width / 3,
                                                  concentricity: 1 - abs(concentricity))

        captionHeight = maxCircumference / 18
        captionBottomPadding = 0

      } else {
        let maxCircumference = concentricityDelta(max: bounds.height,
                                                  min: bounds.width / 3,
                                                  concentricity: 1 - abs(concentricity))

        captionHeight = (maxCircumference / 18)
        captionBottomPadding = 0
      }
    }
  }
}

private extension ConcentricLayout {
  init(bounds: CGRect, layout: RingsViewLayout, focus: RingIdentifier) {
    switch layout.acentricAxis {
    case .alwaysVertical:
      self = ConcentricLayout(isAlwaysPortrait: true, bounds: bounds, layout: layout, focus: focus)

    case .alwaysHorizontal:
      self = ConcentricLayout(isAlwaysPortrait: false, bounds: bounds, layout: layout, focus: focus)

    case .alongLongestDimension:
      self = ConcentricLayout(isAlwaysPortrait: bounds.isPortrait, bounds: bounds, layout: layout, focus: focus)
    }
  }
}

final class RingTextView: UIView {
  var color: UIColor = .label {
    didSet {
      layer.setNeedsDisplay()
    }
  }

  var content: RingData.LabelDetails = .init() {
    didSet {
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
    drawInnerRingText(in: ctx)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
      layer.setNeedsDisplay()
    }
  }

  private func drawInnerRingText(in ctx: CGContext) {
    let headlineFontSize = CGFloat(bounds.width) / 4.0
    let font = UIFont(name: "HelveticaNeue-Light", size: headlineFontSize) ??
      .monospacedSystemFont(ofSize: headlineFontSize, weight: .ultraLight)

    let smallFontSize = CGFloat(bounds.width) / 4.25 / 2
    let smallFont = UIFont(name: "HelveticaNeue-Light", size: smallFontSize) ??
      .systemFont(ofSize: smallFontSize, weight: .thin)

    let smallLabelAttributes = [NSAttributedString.Key.font: smallFont, NSAttributedString.Key.foregroundColor: color]

    let largeLabelAttributes = [NSAttributedString.Key.font: font,
                                NSAttributedString.Key.foregroundColor: color]

    let valueDescription = NSAttributedString(string: content.value, attributes: largeLabelAttributes)
    let valueBounds = stringBounds(string: valueDescription, ctx: ctx)
    valueDescription.draw(at: CGPoint(x: (bounds.width / 2) - valueBounds.width / 2,
                                      y: (bounds.height / 2) - (valueBounds.height / 1.05)))

    let ringDescription1 = NSAttributedString(string: content.title.0, attributes: smallLabelAttributes)
    let ringDescription2 = NSAttributedString(string: content.title.1, attributes: smallLabelAttributes)

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
}

private extension RingsViewLayout {
  func dragGestureKeyPathFor(bounds: CGRect) -> KeyPath<CGPoint, CGFloat> {
    switch acentricAxis {
    case .alwaysVertical:
      return \CGPoint.y

    case .alwaysHorizontal:
      return \CGPoint.x

    case .alongLongestDimension:
      return bounds.isPortrait
        ? \CGPoint.y
        : \CGPoint.x
    }
  }
}

func stringBounds(string: NSAttributedString, ctx: CGContext) -> CGRect {
  let captionValueDimensions = CTLineCreateWithAttributedString(string)
  return CTLineGetImageBounds(captionValueDimensions, ctx)
}

final class LabelView: UIView {
  var text: String = "" {
    didSet { layer.setNeedsDisplay() }
  }

  var textColor: UIColor = .label {
    didSet { layer.setNeedsDisplay() }
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

  override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
      layer.setNeedsDisplay()
    }
  }

  private func drawCaption(in ctx: CGContext) {
    let fontSize = CGFloat(bounds.height)
    let smallFont = UIFont(name: "HelveticaNeue-Light", size: fontSize) ??
      .systemFont(ofSize: fontSize, weight: .thin)

    let captionAttributes = [
      NSAttributedString.Key.font: smallFont,
      NSAttributedString.Key.foregroundColor: textColor,
    ]

    let caption = NSAttributedString(string: text, attributes: captionAttributes)
    let captionBounds = stringBounds(string: caption, ctx: ctx)
    caption.draw(at: CGPoint(x: (bounds.width / 2) - (captionBounds.width / 2),
                             y: (bounds.height) - (captionBounds.height + (captionBounds.height / 2))))
  }
}

public extension RingsViewState {
  init() {
    content = RingsData()
    layout = RingsViewLayout(acentricAxis: .alongLongestDimension,
                             concentricity: 0.0,
                             scaleFactorWhenFullyAcentric: 1.0,
                             scaleFactorWhenFullyConcentric: 1.0)

    prominentRing = .period
  }
}

public func detachedLabelAnimation(animation: @escaping () -> Void) {
  UIView.animate(withDuration: 0.55,
                 delay: 0.0,
                 usingSpringWithDamping: 0.65,
                 initialSpringVelocity: 0.45,
                 options: [.allowUserInteraction]) {
    animation()
  }
}

func restrain(value: CGFloat, in range: ClosedRange<CGFloat>, factor _: CGFloat) -> CGFloat {
  if value > range.upperBound {
    let overShoot = value - range.upperBound
    let resistance = overShoot / (1 + (overShoot * 2.2))

    return range.upperBound + resistance
  }

  if value <= range.lowerBound {
    let overShoot = range.lowerBound - value
    let resistance = -overShoot / (1 + (overShoot * 2.2))

    return range.lowerBound + resistance
  }

  return value
}

public func assertMainThread(_ file: StaticString = #file, line: UInt = #line) {
  assert(Thread.isMainThread, "Code at \(file):\(line) must run on main thread!")
}
