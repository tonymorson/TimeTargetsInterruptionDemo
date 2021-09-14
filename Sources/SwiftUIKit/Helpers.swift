import Combine
import Foundation
import UIKit

public func HStack(spacing: CGFloat = 10, @UIViewBuilder content: () -> [UIView]) -> UIStackView {
  let view = UIStackView(arrangedSubviews: content())

  view.spacing = spacing
  view.distribution = .equalSpacing

  return view
}

@resultBuilder
public enum UIViewBuilder {
  public static func buildBlock(_ views: UIView...) -> [UIView] {
    views
  }
}

public class Label: UILabel {
  var cancellables: [AnyCancellable] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public init(value: AnyPublisher<String, Never>, alignment: NSTextAlignment? = nil) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false

    if let alignment = alignment {
      textAlignment = alignment
    }

    value.sink { [weak self] text in
      self?.text = text
      self?.sizeToFit()
    }
    .store(in: &cancellables)
  }
}

public class ImageView: UIImageView {
  weak var cancellable: AnyCancellable?

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public init(systemName: AnyPublisher<String, Never>) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false

    contentMode = .scaleAspectFit

    cancellable = systemName.map(UIImage.init(systemName:))
      .assign(to: \.image, on: self)
  }
}

public final class Button: UIButton {
  var cancellables: [AnyCancellable] = []
  var callback: () -> Void = {}

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public init(imageSystemName: AnyPublisher<String, Never>, callback: @escaping () -> Void) {
    self.callback = callback

    super.init(frame: .zero)

    addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

    imageSystemName.sink { [weak self] in
      self?.setImage(UIImage(systemName: $0), for: .normal)
    }
    .store(in: &cancellables)
  }

  public init(imageSystemName: String, callback: @escaping () -> Void) {
    self.callback = callback

    super.init(frame: .zero)

    addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

    setImage(UIImage(systemName: imageSystemName), for: .normal)
  }

  @objc func buttonTapped(sender _: UIButton) {
    callback()
  }
}

public class DetailRow: UITableViewCell {
  private var cancellables: Set<AnyCancellable> = []

  init(reuseIdentifier: String = "", title: String, detail: AnyPublisher<String, Never>, accessory: UITableViewCell.AccessoryType = .none) {
    super.init(style: .value1, reuseIdentifier: reuseIdentifier)

    textLabel?.text = title
    accessoryType = accessory
    detail.assign(to: \.detailValue, on: self)
      .store(in: &cancellables)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var detailValue: String {
    set { detailTextLabel?.text = newValue }
    get { detailTextLabel?.text ?? "" }
  }
}

public extension UIViewController {
  func navigationBarTitle(_ title: String) -> Self {
    self.title = title

    return self
  }

  func setLargeTitleDisplayMode(_ mode: UINavigationItem.LargeTitleDisplayMode) -> Self {
    navigationItem.largeTitleDisplayMode = mode

    return self
  }
}

public extension UIViewController {
  @discardableResult
  func navigationBarItems(@MenuItemsBuilder trailing: () -> [UIBarButtonItem]) -> Self {
    navigationItem.rightBarButtonItems = trailing()

    return self
  }

  @discardableResult
  func navigationBarItems(@MenuItemsBuilder leading: () -> [UIBarButtonItem]) -> Self {
    navigationItem.leftBarButtonItems = leading()

    return self
  }

  @discardableResult
  func navigationBarItems(leading: () -> [UIBarButtonItem], trailing: () -> [UIBarButtonItem]) -> Self {
    navigationBarItems(leading: leading)
    navigationBarItems(trailing: trailing)

    return self
  }
}

@resultBuilder
public enum MenuItemsBuilder {
  public static func buildBlock(_ buttons: UIBarButtonItem...) -> [UIBarButtonItem] {
    buttons
  }
}

public extension UINavigationController {
  @discardableResult
  func setPrefersLargeTitle(_ large: Bool) -> Self {
    navigationBar.prefersLargeTitles = large

    return self
  }
}

// NSLayoutConstraints

@resultBuilder
public enum NSLayoutConstraintsBuilder {
  public static func buildBlock(_ constraints: NSLayoutConstraint...) -> [NSLayoutConstraint] {
    constraints
  }
}

public extension UIView {
  @discardableResult
  func constraints(@NSLayoutConstraintsBuilder constraints: (UIView) -> [NSLayoutConstraint]) -> Self {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate(constraints(self))

    return self
  }
}

public extension UIView {
  @discardableResult
  func moveTo(_ view: UIView, @NSLayoutConstraintsBuilder constraints: (UIView, UIView) -> [NSLayoutConstraint]) -> Self {
    removeFromSuperview()
    view.addSubview(self)
    translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate(
      constraints(self, view)
        .filter { !($0 is ReactiveLayoutConstraint) }
    )

    return self
  }
}

public final class ToggleRow: UITableViewCell {
  private let toggle: ReactiveUISwitch

  public init(title: String,
              subtitle: String? = nil,
              isOn: AnyPublisher<Bool, Never>,
              callback: @escaping (Bool) -> Void)
  {
    toggle = ReactiveUISwitch(isOn: isOn, callback: callback)

    super.init(style: .subtitle, reuseIdentifier: title)

    selectionStyle = .none
    accessoryView = toggle
    textLabel?.text = title
    detailTextLabel?.text = subtitle
    detailTextLabel?.textColor = .secondaryLabel
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func makeCell() -> UITableViewCell {
    UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
  }
}

public func Toggle(title: String,
                   subtitle: String? = nil,
                   isOn: AnyPublisher<Bool, Never>,
                   callback: @escaping (Bool) -> Void) -> UITableViewCell
{
  ToggleRow(title: title, subtitle: subtitle, isOn: isOn, callback: callback)
}

public func Toggle(isOn: AnyPublisher<Bool, Never>,
                   callback: @escaping (Bool) -> Void) -> UISwitch
{
  ReactiveUISwitch(isOn: isOn, callback: callback)
}
