import Foundation
import UIKit

public func UIBarButtonItem(_ systemItem: UIBarButtonItem.SystemItem, callback: @escaping () -> Void) -> UIBarButtonItem {
  UIBarButtonItem(systemItem: systemItem, primaryAction: UIAction(handler: { _ in callback() }))
}
