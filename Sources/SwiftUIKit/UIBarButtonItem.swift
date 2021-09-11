import Foundation
import UIKit

// public extension UIBarButtonItem {
//  static func makeWith(systemItem: UIBarButtonItem.SystemItem, callback: @escaping () -> ()) -> UIBarButtonItem {
//    UIBarButtonItem(systemItem: systemItem, primaryAction: UIAction(handler: { _ in  callback() }))
//  }
// }

public func UIBarButtonItem(_ systemItem: UIBarButtonItem.SystemItem, callback: @escaping () -> Void) -> UIBarButtonItem {
  UIBarButtonItem(systemItem: systemItem, primaryAction: UIAction(handler: { _ in callback() }))
}
