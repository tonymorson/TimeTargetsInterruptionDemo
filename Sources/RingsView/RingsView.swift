import Combine
import ComposableArchitecture
import UIKit

public enum RingIdentifier: Int, Codable { case period, session, target }

@MainActor
public final class RingsView: UIView {
  let viewStore: ViewStore<RingsViewState, RingsViewAction>

  public init(viewStore: ViewStore<RingsViewState, RingsViewAction>) {
    self.viewStore = viewStore

    super.init(frame: .zero)

    setup()

    viewStore.publisher
      .map(\.layoutViewModelData)
      .removeDuplicates()
      .sink { [weak self] in self?.update(layout: $0) }
      //      .sink { _ in self.setNeedsLayout()
      .store(in: &cancellables)

    viewStore.publisher
      .map(\.contentViewModelData)
      .removeDuplicates()
      .sink { [weak self] in self?.update(content: $0) }
      .store(in: &cancellables)
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

    apply(layout: AnnotatedRingsLayoutModel(bounds: bounds, state: viewStore.layoutViewModelData))
  }

  override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      update(content: viewStore.contentViewModelData)
    }
  }

  private var cancellables: Set<AnyCancellable> = []

  private let periodTrack = RingView(frame: .zero)
  private let sessionTrack = RingView(frame: .zero)
  private let targetTrack = RingView(frame: .zero)
  private let focusTrack = RingView(frame: .zero)

  private let period = AnnotatedRingView(frame: .zero)
  private let session = AnnotatedRingView(frame: .zero)
  private let target = AnnotatedRingView(frame: .zero)
  private let focus = AnnotatedRingView(frame: .zero)
  private let detachedPeriodLabel = LabelView(frame: .zero)

  private let pan = UIPanGestureRecognizer()
  private let pinch = UIPinchGestureRecognizer()
  private let tap = UITapGestureRecognizer()

  private var savedRingScaleFactor: CGFloat = .zero
  private var savedLayoutKeyPath: WritableKeyPath<RingsViewState, RingsViewState.LayoutState.ConcentricityState>!
  private var panStart: (RingIdentifier, CGPoint)?
  private var panStartConcentricity: CGFloat = 0.0

  private var layoutDirection: RingsViewState.LayoutState.ConcentricityState.Axis {
    switch viewStore.layout.portrait.spread {
    case .vertical: return .vertical
    case .horizontal: return .horizontal
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

  private var focusRingKeyPath: KeyPath<RingsView, AnnotatedRingView> {
    switch viewStore.prominentRing {
    case .period:
      return \.period
    case .session:
      return \.session
    case .target:
      return \.target
    }
  }

  private func apply(layout: AnnotatedRingsLayoutModel) {
    layout.period.apply(to: period)
    layout.session.apply(to: session)
    layout.target.apply(to: target)
    layout.focusLayout.apply(to: focus)

    //    period.apply(layout: concentricLayout.period)
    //    session.apply(layout: concentricLayout.session)
    //    target.apply(layout: concentricLayout.target)
    //    focus.apply(layout: concentricLayout.focusLayout)

    periodTrack.bounds = period.bounds
    periodTrack.center = period.center
    periodTrack.zIndex = period.zIndex
    periodTrack.layer.transform = layout.period.transform

    sessionTrack.bounds = session.bounds
    sessionTrack.center = session.center
    sessionTrack.zIndex = session.zIndex
    sessionTrack.layer.transform = layout.period.transform

    targetTrack.bounds = target.bounds
    targetTrack.center = target.center
    targetTrack.zIndex = target.zIndex
    targetTrack.layer.transform = layout.period.transform

    focusTrack.bounds = focus.bounds
    focusTrack.center = focus.center
    focusTrack.zIndex = focus.zIndex
    focusTrack.layer.transform = focus.layer.transform

    let detachedLabelLayout = layout.detachedLabel
    detachedPeriodLabel.bounds = detachedLabelLayout.bounds
    detachedPeriodLabel.center = detachedLabelLayout.center
    detachedPeriodLabel.layer.transform = detachedLabelLayout.transform

    focus.alpha = layout.focusAlpha
    focusTrack.alpha = layout.focusAlpha
  }

  private func setup() {
    precondition(backgroundColor == nil && subviews.isEmpty,
                 "Set up was already called! Setup should only be called once from the initializer.")

    backgroundColor = .systemBackground

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
  }

  private func update(content: RingsViewState.ContentInformation) {
    let content = AnnotatedRingsContentModel(contentInfo: content)

    period.text.content.titleLine1 = content.period.0
    period.text.content.titleLine2 = content.period.1
    period.text.content.value = ""
    period.text.content.subtitle = content.period.3
    period.text.content.caption = content.period.4
    period.ring.value = content.period.5
    period.caption.text = content.period.4

    period.ring.color = content.period.6.color
    periodTrack.color = content.period.7.color

    session.text.content.titleLine1 = content.session.0
    session.text.content.titleLine2 = content.session.1
    session.text.content.value = content.session.2
    session.text.content.subtitle = content.session.3
    session.text.content.caption = content.session.4
    session.ring.value = content.session.5
    session.caption.text = content.session.4

    session.ring.color = content.session.6.color
    sessionTrack.color = content.session.7.color

    target.text.content.titleLine1 = content.target.0
    target.text.content.titleLine2 = content.target.1
    target.text.content.value = content.target.2
    target.text.content.subtitle = content.target.3
    target.text.content.caption = content.target.4
    target.ring.value = content.target.5
    target.caption.text = content.target.4

    target.ring.color = content.target.6.color
    targetTrack.color = content.target.7.color

    focus.text.content.titleLine1 = content.focus.0
    focus.text.content.titleLine2 = content.focus.1
    focus.text.content.value = content.focus.2
    focus.text.content.subtitle = content.focus.3
    focus.text.content.caption = content.focus.4
    focus.ring.value = content.focus.5
    focus.caption.text = content.focus.4

    focus.ring.color = content.focus.6.color
    focusTrack.color = content.focus.7.color

    detachedPeriodLabel.text = content.period.2
  }

  private func update(layout: RingsViewState.LayoutInformation) {
    if isPortrait {
      apply(layout: AnnotatedRingsLayoutModel(bounds: bounds, state: layout))
    } else {
      apply(layout: AnnotatedRingsLayoutModel(bounds: bounds, state: layout))
    }
  }
}

extension RingsView {
  @objc private func onPan(gesture: UIPanGestureRecognizer) {
    let dragDirectionModifier: CGFloat

    switch panStart {
    case .some(let value) where value.0 == .period:
      dragDirectionModifier = 1

    case .some(let value) where value.0 == .session && layoutDirection == .vertical:
      dragDirectionModifier = value.1.y - 20 > bounds.height / 2 ? -1 : 1

    case .some(let value) where value.0 == .session && layoutDirection == .horizontal:
      dragDirectionModifier = value.1.x > bounds.width / 2 ? -1 : 1

    case .some(let value) where value.0 == .target:
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
      savedLayoutKeyPath = isPortrait ? \RingsViewState.layout.portrait : \RingsViewState.layout.landscape

      panStart?.1 = gesture.location(in: self)
      canAnimateZIndex = false
      panStartConcentricity = viewStore.state[keyPath: savedLayoutKeyPath].concentricity

      let gestureKeyPath = viewStore.state[keyPath: savedLayoutKeyPath].spreadAxisKeyPathFor(bounds: bounds)
      let dragAmount = -gesture.translation(in: self)[keyPath: gestureKeyPath] * dragDirectionModifier
      let concentricDelta = dragAmount / dimension
      let concentricity = concentricDelta + panStartConcentricity

      viewStore.send(.ringConcentricityDragged(concentricity: concentricity, whilePortrait: isPortrait))

    case .changed:
      let gestureKeyPath = viewStore.state[keyPath: savedLayoutKeyPath].spreadAxisKeyPathFor(bounds: bounds)
      let dragAmount = -gesture.translation(in: self)[keyPath: gestureKeyPath] * dragDirectionModifier
      let concentricDelta = dragAmount / dimension
      let concentricity = restrain(value: concentricDelta + panStartConcentricity,
                                   in: -1.0 ... 1.0,
                                   factor: 118.4)

      viewStore.send(.ringConcentricityDragged(concentricity: concentricity, whilePortrait: isPortrait))

    case .ended:
      canAnimateZIndex = true
      panStart = nil

      let gestureKeyPath = viewStore.state[keyPath: savedLayoutKeyPath].spreadAxisKeyPathFor(bounds: bounds)
      let dragAmount = -gesture.translation(in: self)[keyPath: gestureKeyPath]

      let velocity = gesture.velocity(in: self)
      let projectedTranslation = UIGestureRecognizer.project(isPortrait ? velocity.y : velocity.x, onto: -dragAmount) * dragDirectionModifier

      let concentricDelta = -projectedTranslation / dimension
      let concentricity = concentricDelta + panStartConcentricity
      let restingConcentricity = max(-1, min(1, concentricity.rounded()))

      let damping: CGFloat
      let springVelocity: CGFloat

      let dimensionalVelocity = abs(isPortrait ? velocity.y : velocity.x)

      switch dimensionalVelocity {
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
        self.viewStore.send(.ringConcentricityDragged(concentricity: restingConcentricity,
                                                      whilePortrait: self.isPortrait))
      }
    case .cancelled:
      break
    case .failed:
      break
    @unknown default:
      break
    }
  }

  @objc private func onPinch(gesture: UIPinchGestureRecognizer) {
    switch gesture.state {
    case .began:
      savedLayoutKeyPath = isPortrait ? \RingsViewState.layout.portrait : \RingsViewState.layout.landscape
      savedRingScaleFactor = viewStore.state[keyPath: savedLayoutKeyPath].scaleFactor

      let newValue = restrain(value: gesture.scale * savedRingScaleFactor, in: 0.55 ... 0.999999, factor: 2.2)

      viewStore.send(viewStore.state[keyPath: savedLayoutKeyPath].concentricity == 0.0
        ? .concentricRingsPinched(scaleFactor: newValue, whilePortrait: isPortrait)
        : .acentricRingsPinched(scaleFactor: newValue, whilePortrait: isPortrait))

    case .changed:
      let newValue = restrain(value: gesture.scale * savedRingScaleFactor, in: 0.55 ... 0.999999, factor: 2.2)

      viewStore.send(viewStore.state[keyPath: savedLayoutKeyPath].concentricity == 0.0
        ? .concentricRingsPinched(scaleFactor: newValue, whilePortrait: isPortrait)
        : .acentricRingsPinched(scaleFactor: newValue, whilePortrait: isPortrait))

    case .ended:
      let pinchScale = restrain(value: gesture.scale * savedRingScaleFactor, in: 0.55 ... 0.999999, factor: 2.2)
      let clampedScale = max(0.55, min(1.0, pinchScale))

      UIView.animate(withDuration: 0.45,
                     delay: 0.0,
                     usingSpringWithDamping: 0.5,
                     initialSpringVelocity: 0.5,
                     options: [.allowUserInteraction]) {
        self.viewStore.send(self.viewStore.state[keyPath: self.savedLayoutKeyPath].concentricity == 0.0
          ? .concentricRingsPinched(scaleFactor: clampedScale, whilePortrait: self.isPortrait)
          : .acentricRingsPinched(scaleFactor: clampedScale, whilePortrait: self.isPortrait))
      }

    case .possible:
      break

    default:
      fatalError()
      //      viewStore.state[keyPath: savedLayoutKeyPath].scaleFactorWhenFullyConcentric = savedRingScaleFactor
    }
  }

  @objc private func onTap(gesture: UITapGestureRecognizer) {
    if let ring = ringHitTest(for: gesture) {
      viewStore.send(.ringsViewTapped(ring))
      return
    }

    if focus.point(inside: gesture.location(in: focus), with: nil) {
      let midPoint = CGPoint(x: focus.bounds.midX, y: focus.bounds.midY)
      let focusInnerRadius = target.ring.innerRadius
      let periodOuterRadius = period.ring.outerRadius
      let distance = distanceBetween(point: gesture.location(in: focus), and: midPoint)

      if distance >= focusInnerRadius, distance < periodOuterRadius {
        UIView.animate(withDuration: 0.55,
                       delay: 0.0,
                       usingSpringWithDamping: 0.65,
                       initialSpringVelocity: 0.45,
                       options: [.allowUserInteraction]) {
          self.viewStore.send(.concentricRingsTappedInColoredBandsArea)
        }

        return
      }
    }

    viewStore.send(.ringsViewTapped(nil))
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
        switch viewStore.prominentRing {
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

private extension UIGestureRecognizer {
  static func project(_ velocity: CGFloat,
                      onto position: CGFloat,
                      decelerationRate: UIScrollView.DecelerationRate = .normal) -> CGFloat
  {
    position - 0.001 * velocity / log(decelerationRate.rawValue)
  }
}

func distanceBetween(point: CGPoint, and otherPoint: CGPoint) -> CGFloat {
  sqrt(pow(otherPoint.x - point.x, 2) + pow(otherPoint.y - point.y, 2))
}

private extension AnnotatedRingsLayoutModel {
  init(bounds: CGRect, state: RingsViewState.LayoutInformation) {
    let layout = bounds.isPortrait ? state.layout.portrait : state.layout.landscape

    switch layout.spread {
    case .vertical:
      self = AnnotatedRingsLayoutModel(isAlwaysPortrait: true, bounds: bounds, layout: layout, focus: state.prominentRing)

    case .horizontal:
      self = AnnotatedRingsLayoutModel(isAlwaysPortrait: false, bounds: bounds, layout: layout, focus: state.prominentRing)
    }
  }
}

func stringBounds(string: NSAttributedString, ctx: CGContext) -> CGRect {
  let line = CTLineCreateWithAttributedString(string)
  return CTLineGetImageBounds(line, ctx)
}

final class LabelView: UIView {
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

  var text: String = "" {
    didSet { layer.setNeedsDisplay() }
  }

  override func draw(_ layer: CALayer, in ctx: CGContext) {
    super.draw(layer, in: ctx)
    UIGraphicsPushContext(ctx)
    defer { UIGraphicsPopContext() }
    drawCaption(in: ctx)
  }

  private func setupLayer() {
    layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    layer.contentsScale = UIScreen.main.scale * 3
  }

  private func drawCaption(in ctx: CGContext) {
    let fontSize = CGFloat(bounds.height)
    let smallFont = UIFont(name: "HelveticaNeue-Light", size: fontSize) ??
      .systemFont(ofSize: fontSize, weight: .thin)

    let captionAttributes = [
      NSAttributedString.Key.font: smallFont,

      // Pick out a text color suitable for the current theme.
      // We are doing this here because we can't rely on traitCollectionDidChange
      // to update us properly when overrideUserInterfaceStyle value is set.
      // https://stackoverflow.com/questions/58557847/ios-13-dark-mode-traitcollectiondidchange-only-called-the-first-time
      NSAttributedString.Key.foregroundColor: traitCollection.userInterfaceStyle.rawValue == 1
        ? UIColor.darkText
        : .white,
    ]

    let caption = NSAttributedString(string: text, attributes: captionAttributes)
    let captionBounds = stringBounds(string: caption, ctx: ctx)
    caption.draw(at: CGPoint(x: (bounds.width / 2) - (captionBounds.width / 2),
                             y: (bounds.height) - (captionBounds.height + (captionBounds.height / 2))))
  }
}

extension RingsViewState {
  struct LayoutInformation: Equatable {
    var layout: LayoutState
    var prominentRing: RingIdentifier
  }

  var layoutViewModelData: LayoutInformation {
    .init(layout: layout, prominentRing: prominentRing)
  }

  struct ContentInformation: Equatable {
    var content: ContentState
    var prominentRing: RingIdentifier
  }

  var contentViewModelData: ContentInformation {
    .init(content: content, prominentRing: prominentRing)
  }
}
