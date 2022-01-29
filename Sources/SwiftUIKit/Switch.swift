import Combine
import UIKit

final class ReactiveUISwitch: UISwitch {
  private let callback: (Bool) -> Void
  private var cancellables: Set<AnyCancellable> = []

  public init(isOn: AnyPublisher<Bool, Never>,
              callback: @escaping (Bool) -> Void)
  {
    self.callback = callback

    super.init(frame: .zero)

    addTarget(self, action: #selector(buttonTapped), for: .valueChanged)

    isOn.sink { [weak self] isOn in
      guard self?.isOn != isOn else { return }

      self?.setOn(isOn, animated: true)
    }
    .store(in: &cancellables)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func buttonTapped(sender: UISwitch) {
    callback(sender.isOn)
  }
}
