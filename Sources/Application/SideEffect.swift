import Foundation

struct Effect {
  enum EffectType {
    case action(() async -> AppAction)
    case fireAndForget(() async -> Void)
  }

  var f: EffectType

  static func fireAndForget(_ f: @escaping () async -> Void) -> Effect {
    Effect(f: .fireAndForget(f))
  }

  static func send(_ f: @escaping () -> AppAction) -> Effect {
    Effect(f: .action(f))
  }

  static var none: Effect {
    Effect(f: .fireAndForget {})
  }
}
