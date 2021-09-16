import Combine
import Foundation
import UIKit

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

public extension UIView {
  @discardableResult
  func host(_ view: UIView, @NSLayoutConstraintsBuilder constraints: (UIView, UIView) -> [NSLayoutConstraint]) -> Self {
    view.removeFromSuperview()
    addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate(
      constraints(view, self)
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
