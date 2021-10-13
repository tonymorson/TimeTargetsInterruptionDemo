import Foundation
import UIKit

public final class RingsPopupMenuView: UIButton {
  public var title: (String, UIColor) = ("", .label) {
    didSet {
      DispatchQueue.main.async {
        var title = AttributedString(self.title.0)
        title.font = UIFont.systemFont(ofSize: 21, weight: .light).rounded()
        title.foregroundColor = self.title.1
        self.configuration?.attributedTitle = title
      }
    }
  }

  public var subtitle: (String, UIColor) = ("", .label) {
    didSet {
      DispatchQueue.main.async {
        var title = AttributedString(self.subtitle.0)
        title.font = UIFont.systemFont(ofSize: 17, weight: .light)
        title.foregroundColor = self.subtitle.1

        self.configuration?.imagePlacement = .bottom
        self.configuration?.imagePadding = 8
        self.configuration?.imageColorTransformer = .grayscale
        self.configuration?.attributedSubtitle = title
      }
    }
  }

  public var menuItems: [UIMenuElement] = [] {
    didSet {
      DispatchQueue.main.async {
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

    titleLabel?.adjustsFontSizeToFitWidth = true
    subtitleLabel?.adjustsFontSizeToFitWidth = true

    titleLabel?.numberOfLines = 1
    subtitleLabel?.numberOfLines = 1
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
