import Foundation

public enum Interruption: Int, CaseIterable, Codable, Hashable {
  // Distractions
  case conversation
  case daydreaming
  case email
  case message
  case phone
  case socialMedia

  // Interruptions
  case finished
  case health
  case lunch
  case meeting
  case powerFailure
  case restroom
  case tired
  case underTheWeather

  // Other
  case other
}

public extension Interruption {
  static var general: [Interruption] {
    [
      .conversation,
      .daydreaming,
      .email,
      .message,
      .phone,
      .socialMedia,
    ]
  }

  static var more: [Interruption] {
    allCases.filter { !Self.general.contains($0) }
  }
}

public extension Interruption {
  var title: String {
    switch self {
    case .conversation:
      return "Casual Conversation"
    case .daydreaming:
      return "Temporary Concentration Loss"
    case .email:
      return "Email"
    case .finished:
      return "Finished Early"
    case .health:
      return "Other Health Reasons"
    case .lunch:
      return "Lunch"
    case .message:
      return "Text Message"
    case .meeting:
      return "Scheduled Event / Needed Elsewhere"
    case .phone:
      return "Phone Call"
    case .powerFailure:
      return "Equipment/Power Failure"
    case .restroom:
      return "Restroom"
    case .socialMedia:
      return "Social Media"
    case .tired:
      return "Feeling Tired"
    case .underTheWeather:
      return "Feeling Unwell"

    case .other:
      return "Other"
    }
  }

  var conciseTitle: String {
    switch self {
    case .conversation:
      return "Conversation"
    case .daydreaming:
      return "Daydreaming"
    case .email:
      return "Email"
    case .finished:
      return "Finished Early"
    case .health:
      return "Health Issue"
    case .lunch:
      return "Lunch"
    case .message:
      return "Text Message"
    case .meeting:
      return "Needed Elsewhere"
    case .phone:
      return "Phone"
    case .powerFailure:
      return "Power Failure"
    case .restroom:
      return "Restroom"
    case .socialMedia:
      return "Social Media"
    case .tired:
      return "Feeling Tired"
    case .underTheWeather:
      return "Feeling Unwell"

    case .other:
      return "Other"
    }
  }

  var imageName: String {
    let name: String

    switch self {
    case .email:
      name = "at"
    case .conversation:
      name = "person"
    case .daydreaming:
      name = "scribble"
    case .finished:
      name = "checkmark"
    case .health:
      name = "heart"
    case .lunch:
      name = "smallcircle.circle"
    case .meeting:
      name = "calendar"
    case .message:
      name = "message"
    case .phone:
      name = "phone"
    case .powerFailure:
      name = "bolt"
    case .restroom:
      name = "leaf"
    case .socialMedia:
      name = "person.2"
    case .tired:
      name = "battery.25"
    case .underTheWeather:
      name = "umbrella"

    case .other:
      name = "exclamationmark"
    }

    return name
  }
}
