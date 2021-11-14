import ComposableArchitecture
import Foundation
import Ticks
import Timeline
import TimelineTickEffect
import UIKit

public struct RingsViewState: Equatable {
  public var content: ContentState
  public var layout: LayoutState
  public var prominentRing: RingIdentifier

  public init() {
    content = ContentState(tick: .zero, timeline: .init())
    layout = LayoutState(portrait: .init(concentricity: 0.0,
                                         scaleFactorAcentric: 1.0,
                                         scaleFactorConcentric: 1.0,
                                         acentricSpread: .vertical),

                         landscape: .init(concentricity: 1.0,
                                          scaleFactorAcentric: 1.0,
                                          scaleFactorConcentric: 1.0,
                                          acentricSpread: .horizontal))
    prominentRing = .period
  }

  public init(content: ContentState,
              layout: LayoutState,
              prominentRing: RingIdentifier)
  {
    self.content = content
    self.layout = layout

    self.prominentRing = prominentRing
  }

  public struct ContentState: Equatable {
    public var tick: Tick
    public var timeline: Timeline

    public init(tick: Tick, timeline: Timeline) {
      self.tick = tick
      self.timeline = timeline
    }
  }

  public struct LayoutState: Equatable {
    public var portrait: ConcentricityState
    public var landscape: ConcentricityState

    public init(portrait: RingsViewState.LayoutState.ConcentricityState,
                landscape: RingsViewState.LayoutState.ConcentricityState)
    {
      self.portrait = portrait
      self.landscape = landscape
    }

    public struct ConcentricityState: Equatable {
      public var concentricity: CGFloat
      public var (scaleFactorAcentric, scaleFactorConcentric): (CGFloat, CGFloat)
      public var spread: Axis

      public enum Axis: Equatable {
        case vertical, horizontal
      }

      public init(concentricity: CGFloat,
                  scaleFactorAcentric: CGFloat,
                  scaleFactorConcentric: CGFloat,
                  acentricSpread: RingsViewState.LayoutState.ConcentricityState.Axis)
      {
        self.concentricity = concentricity
        self.scaleFactorAcentric = scaleFactorAcentric
        self.scaleFactorConcentric = scaleFactorConcentric
        spread = acentricSpread
      }

      var scaleFactor: CGFloat {
        // Return a derived scale factor by blending both acentric and
        // concentric scale factors together depending on the current
        // concentricity value.
        valueInConcentricRangeAt(concentricity: abs(concentricity),
                                 concentricMax: scaleFactorConcentric,
                                 acentricMin: scaleFactorAcentric)
      }

      func spreadAxisKeyPathFor(bounds _: CGRect) -> KeyPath<CGPoint, CGFloat> {
        // Return the coordinate keypath to use for correctly positioning
        // the rings along the preferred horizontal or vertical axis.
        switch spread {
        case .vertical:
          return \CGPoint.y

        case .horizontal:
          return \CGPoint.x
        }
      }
    }
  }
}

public enum RingsViewAction: Equatable, Codable {
  case acentricRingsPinched(scaleFactor: CGFloat, whilePortrait: Bool)
  case concentricRingsPinched(scaleFactor: CGFloat, whilePortrait: Bool)
  case concentricRingsTappedInColoredBandsArea
  case ringConcentricityDragged(concentricity: CGFloat, whilePortrait: Bool)
  case ringsViewTapped(RingIdentifier?)
  case timerTicked
}

public struct RingsEnvironment {
  let date: () -> Date

  public init(date: @escaping () -> Date) {
    self.date = date
  }
}

public let ringsViewReducer = Reducer<RingsViewState,
  RingsViewAction,
  RingsEnvironment> { state, action, environment in
  switch action {
  case .acentricRingsPinched(let scaleFactor, let whilePortrait):
    if whilePortrait {
      state.layout.portrait.scaleFactorAcentric = scaleFactor
    } else {
      state.layout.landscape.scaleFactorAcentric = scaleFactor
    }

  case .concentricRingsPinched(let scaleFactor, let whilePortrait):
    if whilePortrait {
      state.layout.portrait.scaleFactorConcentric = scaleFactor
    } else {
      state.layout.landscape.scaleFactorConcentric = scaleFactor
    }

  case .concentricRingsTappedInColoredBandsArea:
    switch state.prominentRing {
    case .period: state.prominentRing = .session
    case .session: state.prominentRing = .target
    case .target: state.prominentRing = .period
    }

  case .ringConcentricityDragged(let concentricity, let isPortrait):
    if isPortrait {
      state.layout.portrait.concentricity = concentricity
    } else {
      state.layout.landscape.concentricity = concentricity
    }

  case .ringsViewTapped(.some):
    var timeline = state.content.timeline
    timeline.toggleCountdown(at: environment.date)
    state.content.timeline = timeline
    state.content.tick = state.content.timeline.countdown.tick(at: environment.date())

    return tickEffect(for: timeline, at: state.content.tick, on: .main)
      .map { _ in .timerTicked }
      .eraseToEffect()

  case .ringsViewTapped(.none):
    break

  case .timerTicked:
    state.content.tick = state.content.timeline.countdown.tick(at: environment.date())
  }

  return .none
}
