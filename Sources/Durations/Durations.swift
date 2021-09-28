import Foundation

public typealias Duration = Measurement<UnitDuration>

public extension Double {
  /// Returns a `Duration` representing `this` value expressed in `milliseconds`.
  var milliseconds: Duration {
    Duration(value: Double(self) / 1000, unit: .seconds)
  }

  /// Returns a `Duration` representing `this` value expressed in `seconds`.
  var seconds: Duration {
    Duration(value: Double(self), unit: .seconds)
  }

  /// Returns a `Duration` representing `this` value expressed in `minutes`.
  var minutes: Duration {
    Duration(value: Double(self), unit: .minutes)
  }

  /// Returns a `Duration` representing `this` value expressed in `hours`.
  var hours: Duration {
    Duration(value: Double(self), unit: .hours)
  }
}

public extension Int {
  /// Returns a `Duration` representing `this` value expressed in `milliseconds`.
  var milliseconds: Duration {
    Double(self).milliseconds
  }

  /// Returns a `Duration` representing `this` value expressed in `seconds`.
  var seconds: Duration {
    Double(self).seconds
  }

  /// Returns a `Duration` representing `this` value expressed in `minutes`.
  var minutes: Duration {
    Double(self).minutes
  }

  /// Returns a `Duration` representing `this` value expressed in `hours`.
  var hours: Duration {
    Double(self).hours
  }
}

public extension Duration {
  var asMilliseconds: Double {
    converted(to: .milliseconds).value
  }

  var asSeconds: Double {
    converted(to: .seconds).value
  }

  var asMinutes: Double {
    converted(to: .minutes).value
  }

  var asHours: Double {
    converted(to: .hours).value
  }
}
