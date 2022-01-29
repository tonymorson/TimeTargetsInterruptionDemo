import Foundation
import UIKit

public final class BarButtonItem: UIBarButtonItem {
  var callback: () -> Void

  public convenience init(_ systemItem: UIBarButtonItem.SystemItem, callback: @escaping () -> Void) {
    self.init(barButtonSystemItem: systemItem, target: nil, action: nil)

    target = self
    action = #selector(onTap)
    self.callback = callback
  }

  override private init() {
    callback = {}

    super.init()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func onTap(sender _: BarButtonItem) {
    callback()
  }
}
