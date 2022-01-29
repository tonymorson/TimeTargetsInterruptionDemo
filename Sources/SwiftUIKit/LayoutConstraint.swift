import Combine
import UIKit

public extension NSLayoutConstraint {
  func reactive(_ publisher: AnyPublisher<CGFloat?, Never>) -> ReactiveLayoutConstraint {
    ReactiveLayoutConstraint(constraint: self, constant: publisher)
  }
}

public final class ReactiveLayoutConstraint: NSLayoutConstraint {
  private var cancellables: Set<AnyCancellable> = []

  override public init() {
    super.init()
  }

  public convenience init(constraint: NSLayoutConstraint, constant: AnyPublisher<CGFloat?, Never>) {
    self.init(item: constraint.firstItem as Any,
              attribute: constraint.firstAttribute,
              relatedBy: constraint.relation,
              toItem: constraint.secondItem,
              attribute: constraint.secondAttribute,
              multiplier: constraint.multiplier,
              constant: constraint.constant)

    constant.sink { value in
      if let value = value {
        self.constant = value
        self.isActive = true
      } else {
        self.isActive = false
      }
    }
    .store(in: &cancellables)
  }
}
