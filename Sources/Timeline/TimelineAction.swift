import Foundation

public enum TimelineAction: Int, Equatable, Codable {
  case pause
  case restartCurrentPeriod
  case resetTimelineToTickZero
  case resume
  case skipCurrentPeriod
  case toggle
  case changedTimeline
}
