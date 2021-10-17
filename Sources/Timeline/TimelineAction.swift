import Foundation

public enum TimelineAction: Equatable, Codable {
  case pause
  case restartCurrentPeriod
  case resetTimelineToTickZero
  case resume
  case skipCurrentPeriod
  case changedTimeline(Timeline)
}
