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
  var excuse: String {
    switch self {
    case .conversation:
      return "Interrupted by conversation"
    case .daydreaming:
      return "Loss of concentration"
    case .email:
      return "Interrupted by email"
    case .finished:
      return "Finished early"
    case .health:
      return "Stopped for health reasons"
    case .lunch:
      return "Stopped for lunch"
    case .message:
      return "Interrupted by text message"
    case .meeting:
      return "Needed elsewhere"
    case .phone:
      return "Interrupted by phone call"
    case .powerFailure:
      return "Interrupted by power failure"
    case .restroom:
      return "Paused for call of nature"
    case .socialMedia:
      return "Interrupted by social media"
    case .tired:
      return "Loss of energy to tiredness"
    case .underTheWeather:
      return "Feeling under the weather"

    case .other:
      return "Countdown interrupted at"
    }
  }

  var distracted: String {
    switch self {
    case .conversation:
      return "Distracted by conversation"
    case .daydreaming:
      return "Loss of concentration"
    case .email:
      return "Distracted by email"
    case .finished:
      return "Finished early"
    case .health:
      return "Stopped for health reasons"
    case .lunch:
      return "Stopped for lunch"
    case .message:
      return "Distracted by text message"
    case .meeting:
      return "Needed elsewhere"
    case .phone:
      return "Distracted by phone call"
    case .powerFailure:
      return "Distracted by power failure"
    case .restroom:
      return "Paused for call of nature"
    case .socialMedia:
      return "Distracted by social media"
    case .tired:
      return "Loss of energy to tiredness"
    case .underTheWeather:
      return "Feeling under the weather"

    case .other:
      return "Countdown interrupted at"
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
      return "Message"
    case .meeting:
      return "Needed Elsewhere"
    case .phone:
      return "Phone"
    case .powerFailure:
      return "Power Failure"
    case .restroom:
      return "Call of nature"
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
