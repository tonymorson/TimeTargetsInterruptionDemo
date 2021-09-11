import SwiftUIKit
import UIKit

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.

    Label().moveTo(view) { label, view in
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    }
    .text = "Hello"
  }
}
