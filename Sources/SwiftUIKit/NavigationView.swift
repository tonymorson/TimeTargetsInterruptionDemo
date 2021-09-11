import Foundation
import UIKit

public func NavigationView(content: () -> UIViewController) -> UINavigationController {
  UINavigationController(rootViewController: content())
    .setPrefersLargeTitle(true)
}
