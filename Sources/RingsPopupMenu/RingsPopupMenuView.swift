import Foundation
import UIKit

public struct RingsPopupMenuState: Equatable {
  public let title: String
  public let subtitle: String

  public init(title: String = "", subtitle: String = "") {
    self.title = title
    self.subtitle = subtitle
  }
}

@MainActor
public final class RingsPopupMenuView: UIButton {
  public var viewModel: RingsPopupMenuState {
    didSet {
      title = (viewModel.title.isEmpty ? " " : viewModel.title, .red)
      subtitle = (viewModel.subtitle.isEmpty ? " " : viewModel.subtitle, .label)
    }
  }

  var title: (String, UIColor) = ("", .label) {
    didSet {
      var title = AttributedString(title.0)
      title.font = UIFont.systemFont(ofSize: 24, weight: .light).rounded()
      title.foregroundColor = self.title.1

      configuration?.attributedTitle = title
    }
  }

  var subtitle: (String, UIColor) = ("", .label) {
    didSet {
      var title = AttributedString(subtitle.0)
      title.font = UIFont.systemFont(ofSize: 20, weight: .light)
      title.foregroundColor = subtitle.1

      configuration?.imagePlacement = .bottom
      configuration?.imagePadding = 8
      configuration?.imageColorTransformer = .grayscale
      configuration?.attributedSubtitle = title
    }
  }

  public var menuItems: [UIMenuElement] = [] {
    didSet {
      menu = UIMenu(children: menuItems)
    }
  }

  @MainActor public convenience init() {
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
    viewModel = .init()
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
