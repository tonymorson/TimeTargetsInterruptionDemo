import Combine
import Foundation
import UIKit

public final class RingsPopupMenuView: UIButton {
  public var title: (String, UIColor) = ("", .label) {
    didSet {
      DispatchQueue.main.async {
        var title = AttributedString(self.title.0)
        title.font = UIFont.systemFont(ofSize: 19, weight: .light).rounded()
        title.foregroundColor = self.title.1
        self.configuration?.attributedTitle = title
      }
    }
  }

  public var subtitle: (String, UIColor) = ("", .label) {
    didSet {
      DispatchQueue.main.async {
        var title = AttributedString(self.title.0)
        title.font = UIFont.systemFont(ofSize: 13, weight: .light)
        title.foregroundColor = self.title.1
        self.configuration?.attributedSubtitle = title
      }
    }
  }

  public var menuItems: [UIAction] = [] {
    didSet {
      DispatchQueue.main.async {
        print("Hello")
        self.menu = UIMenu(children: self.menuItems)
      }
    }
  }

  public convenience init() {
    var configuration = UIButton.Configuration.gray()
    configuration.cornerStyle = .dynamic
    configuration.baseForegroundColor = UIColor.systemRed
    configuration.baseBackgroundColor = .clear
    configuration.buttonSize = .medium

    configuration.titlePadding = 4
    configuration.titleAlignment = .center

    self.init(configuration: configuration, primaryAction: nil)

    showsMenuAsPrimaryAction = true
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension UIFont {
  func rounded() -> UIFont {
    guard let descriptor = fontDescriptor.withDesign(.rounded) else {
      return self
    }

    return UIFont(descriptor: descriptor, size: pointSize)
  }
}
