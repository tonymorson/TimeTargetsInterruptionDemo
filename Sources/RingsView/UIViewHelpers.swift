import Foundation
import UIKit

public extension UIView {
  var isPortrait: Bool {
    bounds.isPortrait
  }

  var isLandscape: Bool {
    !isPortrait
  }
}

public extension CGRect {
  var isPortrait: Bool {
    size.isPortrait
  }

  var isLandscape: Bool {
    !isPortrait
  }
}

public extension CGSize {
  var isPortrait: Bool {
    height >= width
  }

  var isLandscape: Bool {
    !isPortrait
  }
}
