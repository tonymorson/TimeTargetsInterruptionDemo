import InterruptionPickerView
import UIKit

public struct Section: Hashable {}

class ViewController: UIViewController {
  override func loadView() {
    view = InterruptionPickerView(frame: .zero)
  }
}
