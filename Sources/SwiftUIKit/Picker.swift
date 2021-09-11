import Combine
import Foundation
import UIKit

public protocol CellPickable {
  func makeListPicker() -> UITableViewController
}

public class Picker<V>: UITableViewCell, CellPickable where V: Equatable {
  private var cancellables: Set<AnyCancellable> = []
  private var callback: (V) -> Void
  private var labelText: (V) -> String
  private var sectionTitle: String?
  private var selection: V? {
    didSet {
      if let selection = self.selection {
        detailTextLabel?.text = labelText(selection)
      } else {
        detailTextLabel?.text = ""
      }
    }
  }

  private var values: [V]

  public init(_ title: String,
              subtitle: String? = nil,
              selection: AnyPublisher<V, Never>,
              values: [V],
              valueTitle: @escaping (V) -> String,
              callback: @escaping (V) -> Void)
  {
    self.values = values
    labelText = valueTitle
    sectionTitle = subtitle
    self.callback = callback

    super.init(style: .value1, reuseIdentifier: title)

    textLabel?.text = title
    accessoryType = .disclosureIndicator

    selection.sink { value in
      self.selection = value
    }
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

  public func makeListPicker() -> UITableViewController {
    ListPicker<V>(style: .insetGrouped,
                  title: textLabel?.text ?? "",
                  sectionTitle: sectionTitle,
                  selection: selection!,
                  values: values,
                  rowTitle: labelText,
                  callback: callback)
  }
}

public final class ListPicker<V>: UITableViewController where V: Equatable {
  var callback: (V) -> Void
  var sectionTitle: String?
  var values: [V]
  var selection: V
  var rowTitle: (V) -> String

  init(style: UITableView.Style, title: String, sectionTitle: String? = nil, selection: V, values: [V], rowTitle: @escaping (V) -> String, callback: @escaping (V) -> Void) {
    self.rowTitle = rowTitle
    self.sectionTitle = sectionTitle
    self.selection = selection
    self.values = values
    self.callback = callback
    super.init(style: style)

    self.title = title
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func numberOfSections(in _: UITableView) -> Int {
    navigationItem.largeTitleDisplayMode = .never
    return 1
  }

  override public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    values.count
  }

  override public func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: "Any")

    cell.accessoryType = values[indexPath.item] == selection ? .checkmark : .none
    cell.textLabel?.text = rowTitle(values[indexPath.item])

    return cell
  }

  override public func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
    sectionTitle
  }

  override public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    navigationController?.popViewController(animated: true)

    DispatchQueue.main.async {
      self.callback(self.values[indexPath.item])
    }
  }
}
