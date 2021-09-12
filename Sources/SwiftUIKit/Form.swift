import Combine
import Foundation
import UIKit

public final class Form<V>: UITableViewController {
  private var cancellables: Set<AnyCancellable> = []
  private var content: (AnyPublisher<V, Never>, V) -> [FormSection]
  private var cells: [UITableViewCell] = []
  private var dataSource: ValueFormDiffableDataSource!
  private var onDismiss: () -> Void = {}
  private var userData: AnyPublisher<V, Never>

  deinit {
    onDismiss()
  }

  public init(userData: AnyPublisher<V, Never>, @FormSectionsBuilder content: @escaping (AnyPublisher<V, Never>, V) -> [FormSection]) {
    self.content = content
    self.userData = userData

    super.init(style: .insetGrouped)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    dataSource = .init(tableView: tableView) { [weak self] _, _, itemIdentifier in
      self?.cells.first { $0.reuseIdentifier == itemIdentifier }
    }

    userData.sink { [weak self] value in
      guard let self = self else { return }

      self.cells = self.content(self.userData, value).flatMap { $0.content() }

      var snapshot = NSDiffableDataSourceSnapshot<FormSection, String>()
      snapshot.appendSections(self.content(self.userData, value))
      for section in self.content(self.userData, value) {
        let identifiers = section.content().compactMap(\.reuseIdentifier)
        snapshot.appendItems(identifiers, toSection: section)
      }

      self.dataSource.apply(snapshot)
    }
    .store(in: &cancellables)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func onDismiss(_ callback: @escaping () -> Void) -> Self {
    onDismiss = callback
    return self
  }

  override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)

    if let cell = cell as? CellPickable {
      let vc = cell.makeListPicker()

      navigationController?.pushViewController(vc, animated: true)
    }
  }
}

public func Section(header: String,
                    footer: String? = nil,
                    @UITableViewCellsBuilder content: @escaping () -> [UITableViewCell]) -> FormSection
{
  FormSection(header: header, footer: footer, content: content)
}

public struct FormSection: Hashable {
  public static func == (lhs: FormSection, rhs: FormSection) -> Bool {
    lhs.header == rhs.header
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(header!)
  }

  public var content: () -> [UITableViewCell]
  public var header: String?
  public var footer: String?

  public init(header: String,
              footer: String? = nil,
              @UITableViewCellsBuilder content: @escaping () -> [UITableViewCell])
  {
    self.header = header
    self.footer = footer
    self.content = content
  }
}

@resultBuilder
public enum FormSectionsBuilder {
  public static func buildBlock(_ sections: FormSection...) -> [FormSection] {
    sections
  }

  public static func buildBlock(_ cells: [FormSection]...) -> [FormSection] {
    cells.flatMap { $0 }
  }

  public static func buildEither(first component: [FormSection]) -> [FormSection] {
    component
  }

  public static func buildEither(second component: [FormSection]) -> [FormSection] {
    component
  }

  public static func buildExpression(_ expression: FormSection) -> [FormSection] {
    [expression]
  }

  public static func buildExpression(_: Void) -> [FormSection] {
    []
  }

  public static func buildOptional(_ component: [FormSection]?) -> [FormSection] {
    component ?? []
  }
}

@resultBuilder
public enum UITableViewCellsBuilder {
  public static func buildBlock(_ cells: [UITableViewCell]...) -> [UITableViewCell] {
    cells.flatMap { $0 }
  }

  public static func buildEither(first component: [UITableViewCell]) -> [UITableViewCell] {
    component
  }

  public static func buildEither(second component: [UITableViewCell]) -> [UITableViewCell] {
    component
  }

  public static func buildExpression(_ expression: UITableViewCell) -> [UITableViewCell] {
    [expression]
  }

  public static func buildExpression(_: Void) -> [UITableViewCell] {
    []
  }

  public static func buildOptional(_ component: [UITableViewCell]?) -> [UITableViewCell] {
    component ?? []
  }
}

private class ValueFormDiffableDataSource: UITableViewDiffableDataSource<FormSection, String> {
  override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<FormSection, String>.CellProvider) {
    super.init(tableView: tableView, cellProvider: cellProvider)

    defaultRowAnimation = .middle
  }

  override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
    let section = sectionIdentifier(for: section)

    return section?.header
  }

  override func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
    let section = sectionIdentifier(for: section)

    return section?.footer
  }
}
