import Combine
import Foundation
import UIKit

public struct RingsViewState: Equatable {
  public var arrangement: RingsViewLayout
  public var content: RingsData

  public init(arrangement: RingsViewLayout, content: RingsData) {
    self.arrangement = arrangement
    self.content = content
  }
}

public enum RingSemantic: Int { case period, session, target }

public enum RingsViewAction: Equatable {
  case acentricRingsPinched(scaleFactor: CGFloat)
  case concentricRingsPinched(scaleFactor: CGFloat)
  case concentricRingsTappedInColoredBandsArea
  case ringConcentricityDragged(concentricity: CGFloat)
  case ringsTapped(RingSemantic?)
  case ringSelected(RingSemantic)
}

public func ringsViewReducer(state: inout RingsViewState, action: RingsViewAction, environment _: RingsViewEnvironment) {
  switch action {
  case let .acentricRingsPinched(scaleFactor: scaleFactor):
    state.arrangement.scaleFactorWhenFullyAcentric = scaleFactor

  case let .concentricRingsPinched(scaleFactor: scaleFactor):
    state.arrangement.scaleFactorWhenFullyConcentric = scaleFactor

  case .concentricRingsTappedInColoredBandsArea:
    switch state.arrangement.focus {
    case .period: state.arrangement.focus = .session
    case .session: state.arrangement.focus = .target
    case .target: state.arrangement.focus = .period
    }

  case let .ringConcentricityDragged(newValue):
    state.arrangement.concentricity = newValue

  case .ringsTapped(.some):
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

  case .ringsTapped(.none):
    break

  case let .ringSelected(ring):
    state.arrangement.focus = ring
  }
}

public struct RingsViewEnvironment {
  public init() {}
}

public final class RingsView: UIView {
  @Published public var sentActions: RingsViewAction?

  fileprivate var state = RingsViewState() {
    didSet { update(from: oldValue, to: state) }
  }

  private var cancellables: Set<AnyCancellable> = []
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
    switch state.arrangement.acentricAxis {
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

  public init(input: AnyPublisher<RingsViewState, Never>) {
    super.init(frame: .zero)

    input.sink { value in
      self.state = value
    }
    .store(in: &cancellables)

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

    apply(concentricLayout: ConcentricLayout(bounds: bounds, settings: state.arrangement))
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

    if from.arrangement != to.arrangement {
      apply(concentricLayout: ConcentricLayout(bounds: bounds, settings: to.arrangement))

      if from.arrangement.focus != to.arrangement.focus {
        updateFocusRingDetails()
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

    updateFocusRingDetails()

    detachedPeriodLabel.text = details.period.label.value
  }

  private func updateFocusRingDetails() {
    focus.details = self[keyPath: focusRingKeyPath].details
    focusTrack.color = focus.details.color.darker!

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

    switch state.arrangement.focus {
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
      sentActions = .ringsTapped(ring)
      return
    }

    if focus.point(inside: gesture.location(in: focus), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let focusInnerRadius = target.ring.innerRadius
      let periodOuterRadius = period.ring.outerRadius
      let distance = distanceBetween(point: gesture.location(in: focus), and: midPoint)

      if distance >= focusInnerRadius, distance < periodOuterRadius {
        sentActions = .concentricRingsTappedInColoredBandsArea
        return
      }
    }

    sentActions = .ringsTapped(nil)
  }

  private func ringHitTest(for gesture: UITapGestureRecognizer) -> RingSemantic? {
    if focus.point(inside: gesture.location(in: period), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let focusInnerRadius = target.ring.innerRadius
      let periodOuterRadius = period.ring.outerRadius
      let distance = distanceBetween(point: gesture.location(in: period), and: midPoint)

      if distance >= focusInnerRadius, distance < periodOuterRadius {
        return nil
      }

      if distance < focusInnerRadius {
        switch state.arrangement.focus {
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
  private var savedConcentricKeyPath: WritableKeyPath<RingsViewLayout, CGFloat>!

  @objc private func onPinch(gesture: UIPinchGestureRecognizer) {
    switch gesture.state {
    case .began:
      savedConcentricKeyPath = state.arrangement.concentricity == 0.0
        ? \RingsViewLayout.scaleFactorWhenFullyConcentric
        : \RingsViewLayout.scaleFactorWhenFullyAcentric

      savedRingScaleFactor = state.arrangement[keyPath: savedConcentricKeyPath]

      let newValue = constrainMinPinchingValueIfNeeded(value: gesture.scale * savedRingScaleFactor)

      sentActions = state.arrangement.concentricity == 0.0
        ? .concentricRingsPinched(scaleFactor: newValue)
        : .acentricRingsPinched(scaleFactor: newValue)

    case .changed:
      let newValue = constrainMinPinchingValueIfNeeded(value: gesture.scale * savedRingScaleFactor)

      sentActions = state.arrangement.concentricity == 0.0
        ? .concentricRingsPinched(scaleFactor: newValue)
        : .acentricRingsPinched(scaleFactor: newValue)

    case .ended:
      let pinchScale = constrainMinPinchingValueIfNeeded(value: gesture.scale * savedRingScaleFactor)
      let clampedScale = max(0.55, min(1.0, pinchScale))

      UIView.animate(withDuration: 0.45,
                     delay: 0.0,
                     usingSpringWithDamping: 0.5,
                     initialSpringVelocity: 0.5,
                     options: [.allowUserInteraction]) {
        self.sentActions = self.state.arrangement.concentricity == 0.0
          ? .concentricRingsPinched(scaleFactor: clampedScale)
          : .acentricRingsPinched(scaleFactor: clampedScale)
      }

    case .possible:
      break

    default:
      state.arrangement.scaleFactorWhenFullyConcentric = savedRingScaleFactor
    }
  }

  private var panStart: (RingSemantic, CGPoint)?
  private var panStartConcentricity: CGFloat = 0.0
  @objc private func onPan(gesture: UIPanGestureRecognizer) {
    let dragDirectionModifier: CGFloat

    switch panStart {
    case let .some(value) where value.0 == .period:
      dragDirectionModifier = 1
    case let .some(value) where value.0 == .session && layoutDirection == .vertical:
      if state.arrangement.concentricity > 0 {
        dragDirectionModifier = value.1.y - 20 > bounds.height / 2 ? -1 : 1
      } else {
        dragDirectionModifier = value.1.y + 50 > bounds.height / 2 ? 1 : -1
      }
    case let .some(value) where value.0 == .session && layoutDirection == .horizontal:
      if state.arrangement.concentricity > 0 {
        dragDirectionModifier = value.1.x > bounds.width / 2 ? -1 : 1
      } else {
        dragDirectionModifier = value.1.x > bounds.width / 2 ? 1 : -1
      }
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
      panStart?.1 = gesture.location(in: self)
      canAnimateZIndex = false
      panStartConcentricity = state.arrangement.concentricity

      let gestureKeyPath = state.arrangement.dragGestureKeyPathFor(bounds: bounds)
      let dragAmount = -gesture.translation(in: self)[keyPath: gestureKeyPath] * dragDirectionModifier
      let concentricDelta = dragAmount / dimension
      let concentricity = concentricDelta + panStartConcentricity

      sentActions = .ringConcentricityDragged(concentricity: concentricity)

    case .changed:
      let gestureKeyPath = state.arrangement.dragGestureKeyPathFor(bounds: bounds)
      let dragAmount = -gesture.translation(in: self)[keyPath: gestureKeyPath] * dragDirectionModifier
      let concentricDelta = dragAmount / dimension
      let concentricity = concentricDelta + panStartConcentricity

      sentActions = .ringConcentricityDragged(concentricity: concentricity)

    case .ended:
      canAnimateZIndex = true
      panStart = nil

      let gestureKeyPath = state.arrangement.dragGestureKeyPathFor(bounds: bounds)
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
    switch state.arrangement.focus {
    case .period:
      return \.period
    case .session:
      return \.session
    case .target:
      return \.target
    }
  }

  private func apply(concentricLayout: ConcentricLayout) {
    period.apply(layout: concentricLayout.period)
    session.apply(layout: concentricLayout.session)
    target.apply(layout: concentricLayout.target)
    focus.apply(layout: concentricLayout.focus)

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
    guard panStart == nil else { return true }
    guard gestureRecognizer == pan else { return true }
    guard let ring = testRing(for: touch) else { return true }

    panStart = (ring, touch.location(in: self))
    return true
  }

  private func testRing(for touch: UITouch) -> RingSemantic? {
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
  let vertical: Bool
  let settings: RingsViewLayout

  var captionHeight: CGFloat = 152
  var captionTopPadding: CGFloat { captionHeight / 2.5 }
  var captionBottomPadding: CGFloat = 0

  var captionHeightWithPadding: CGFloat {
    captionHeight + captionTopPadding + captionBottomPadding
  }

  var concentricity: CGFloat {
    settings.concentricity
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
          zoom: settings.scaleFactor)
  }

  struct DetachedLabelConcentricityLayout {
    let bounds: CGRect
    let center: CGPoint
    let transform: CATransform3D
  }

  var detachedLabel: DetachedLabelConcentricityLayout {
    let size = CGSize(width: period.bounds.width * 0.5, height: period.bounds.height * 0.12)

    let detachedPeriodLabelBounds = CGRect(origin: .zero, size: size)
    let detachedPeriodLabelPosition: CGPoint
    let detachedPeriodLabelTransform: CATransform3D

    let detachedPeriodLabelYWhenConcentric = periodCenterY - period.bounds.width / 80
    let detachedPeriodLabelYWhenAcentric = (periodCenterY + ((period.bounds.width / 4) * settings.scaleFactor)) - (41 * (settings.scaleFactor))

    switch settings.focus {
    case .period:
      detachedPeriodLabelPosition = CGPoint(x: periodCenterX, y: detachedPeriodLabelYWhenConcentric)
      detachedPeriodLabelTransform = CATransform3DMakeScale(settings.scaleFactor, settings.scaleFactor, 0.5)

    case .session:

      let scale = valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                           concentricMax: 0.38,
                                           acentricMin: settings.scaleFactor)

      let yPos = valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                          concentricMax: detachedPeriodLabelYWhenAcentric,
                                          acentricMin: detachedPeriodLabelYWhenConcentric)

      detachedPeriodLabelPosition = CGPoint(x: periodCenterX, y: yPos)
      detachedPeriodLabelTransform = CATransform3DScale(CATransform3DMakeScale(scale, scale, 0.5),
                                                        settings.scaleFactor,
                                                        settings.scaleFactor,
                                                        0.5)

    case .target:
      let scale = valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                           concentricMax: 0.38,
                                           acentricMin: settings.scaleFactor)

      let yPos = valueInConcentricRangeAt(concentricity: min(1.0, abs(concentricity)),
                                          concentricMax: detachedPeriodLabelYWhenAcentric,
                                          acentricMin: detachedPeriodLabelYWhenConcentric)

      detachedPeriodLabelPosition = CGPoint(x: periodCenterX, y: yPos)
      detachedPeriodLabelTransform = CATransform3DScale(CATransform3DMakeScale(scale, scale, 0.5), settings.scaleFactor, settings.scaleFactor, 0.5)
    }

    return .init(bounds: detachedPeriodLabelBounds,
                 center: detachedPeriodLabelPosition,
                 transform: detachedPeriodLabelTransform)
  }

  var session: RingConcentricityLayout {
    .init(center: CGPoint(x: sessionCenterX, y: sessionCenterY),
          circumference: ringCircumference,
          textOpacity: textOpacity,
          zIndex: abs(concentricityDelta(max: 1, min: 0, concentricity: 1 - abs(concentricity))),
          zoom: settings.scaleFactor)
  }

  var target: RingConcentricityLayout {
    .init(center: CGPoint(x: targetCenterX, y: targetCenterY),
          circumference: ringCircumference,
          textOpacity: textOpacity,
          zIndex: abs(concentricityDelta(max: 2, min: 0, concentricity: 1 - abs(concentricity))),
          zoom: settings.scaleFactor)
  }

  var focus: RingConcentricityLayout {
    let focusKeyPath: KeyPath<Self, RingConcentricityLayout>

    switch settings.focus {
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

  init(vertical: Bool, bounds: CGRect, settings: RingsViewLayout) {
    self.vertical = vertical
    self.bounds = bounds
    self.settings = settings

    if vertical {
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
  init(bounds: CGRect, settings: RingsViewLayout) {
    switch settings.acentricAxis {
    case .alwaysVertical:
      self = ConcentricLayout(vertical: true, bounds: bounds, settings: settings)

    case .alwaysHorizontal:
      self = ConcentricLayout(vertical: false, bounds: bounds, settings: settings)

    case .alongLongestDimension:
      self = ConcentricLayout(vertical: bounds.isPortrait, bounds: bounds, settings: settings)
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

private func constrainMinPinchingValueIfNeeded(value: CGFloat) -> CGFloat {
  if value > 1 {
    let left = 1.0
    let right = value - left

    let resistance = right / (1 + (right * 2.2))

    return left + resistance
  }

  if value <= 0.55 {
    let left = 0.55
    let right = left - value // - left

    let resistance = -right / (1 + (right * 2.2))

    return left + resistance
  }

  return value
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
    arrangement = RingsViewLayout(acentricAxis: .alongLongestDimension,
                                  concentricity: 0.0,
                                  focus: .period,
                                  scaleFactorWhenFullyAcentric: 1.0,
                                  scaleFactorWhenFullyConcentric: 1.0)
  }
}
