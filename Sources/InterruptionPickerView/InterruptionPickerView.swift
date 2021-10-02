import Foundation
import SwiftUIKit
import Timeline
import UIKit

struct Section: Hashable {}

public final class InterruptionPickerView: UIView {
  var dataSource: UICollectionViewDiffableDataSource<Section, Interruption>!
  var collectionView: UICollectionView!

  override public init(frame: CGRect) {
    super.init(frame: frame)

    setup()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setup() {
    backgroundColor = .systemBackground
    tintColor = .label

    let segmentedControl = UISegmentedControl(items: [general, more, all])

    host(segmentedControl) { control, parent in
      control.leadingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.leadingAnchor, constant: 20)
      control.topAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor, constant: 20)
      control.trailingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.trailingAnchor, constant: -20)
    }
    .selectedSegmentIndex = 0

    let layout = ColumnFlowLayout()
    layout.minimumInteritemSpacing = 0

    collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)

    host(collectionView) { collectionView, parent in
      collectionView.leadingAnchor.constraint(equalTo: segmentedControl.leadingAnchor)
      collectionView.trailingAnchor.constraint(equalTo: segmentedControl.trailingAnchor)
      collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20)
      collectionView.bottomAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.bottomAnchor)
    }

    let reg = UICollectionView.CellRegistration<UICollectionViewListCell, Interruption> { cell, _, interruption in

      var contentConfiguration = cell.defaultContentConfiguration()
//      config.textProperties.numberOfLines = 2
      contentConfiguration.image = UIImage(systemName: interruption.imageName)
      contentConfiguration.text = interruption.conciseTitle

      cell.contentConfiguration = contentConfiguration
    }

    dataSource = UICollectionViewDiffableDataSource<Section, Interruption>(collectionView: collectionView) { collectionView, indexPath, interruption in

      collectionView.dequeueConfiguredReusableCell(using: reg, for: indexPath, item: interruption)
    }

    collectionView.dataSource = dataSource

    var snapshot = NSDiffableDataSourceSnapshot<Section, Interruption>()
    let section = Section()
    snapshot.appendSections([section])
    snapshot.appendItems(Interruption.general, toSection: section)
    dataSource.apply(snapshot)
  }

  lazy var general: UIAction = {
    let action = UIAction(title: "General") { [weak self] _ in
      var snapshot = NSDiffableDataSourceSnapshot<Section, Interruption>()
      let section = Section()
      snapshot.appendSections([section])
      snapshot.appendItems(Interruption.general, toSection: section)
      self?.dataSource.apply(snapshot)
    }

    return action
  }()

  lazy var more: UIAction = {
    let action = UIAction(title: "More") { [weak self] _ in
      var snapshot = NSDiffableDataSourceSnapshot<Section, Interruption>()
      let section = Section()
      snapshot.appendSections([section])
      snapshot.appendItems(Interruption.more, toSection: section)
      self?.dataSource.apply(snapshot)
    }

    return action
  }()

  lazy var all: UIAction = {
    let action = UIAction(title: "All") { [weak self] _ in
      var snapshot = NSDiffableDataSourceSnapshot<Section, Interruption>()
      let section = Section()
      snapshot.appendSections([section])
      snapshot.appendItems(Interruption.allCases, toSection: section)
      self?.dataSource.apply(snapshot)
    }

    return action
  }()
}

class ColumnFlowLayout: UICollectionViewFlowLayout {
  override func prepare() {
    super.prepare()

    guard let collectionView = collectionView else { return }

    let availableWidth = collectionView.bounds.inset(by: collectionView.layoutMargins).width
    let maxNumColumns = Int(availableWidth / 180)
    let cellWidth = (availableWidth / CGFloat(maxNumColumns)).rounded(.down)

    itemSize = CGSize(width: cellWidth, height: 44)
    sectionInset = UIEdgeInsets(top: minimumInteritemSpacing, left: 0.0, bottom: 0.0, right: 0.0)
    sectionInsetReference = .fromSafeArea
  }
}

public enum InterruptionPickerAction {
  case dismissed
  case interruptionTapped(Interruption)
}

public final class InterruptionPicker: UIViewController {
  public var callback: (InterruptionPickerAction) -> Void = { _ in }
  var picker: InterruptionPickerView!

  deinit {
    callback(.dismissed)
  }

  override public func viewDidLoad() {
    view.backgroundColor = .systemBackground

    let title = UILabel()
    let subtitle = UILabel()
    picker = InterruptionPickerView()

    view.host(title) { label, _ in
      label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
      label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
      label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
    }

    title.text = "Work interruption logged at: \(Date().formatted(date: .omitted, time: .shortened))"
    title.textAlignment = .center
    title.textColor = .systemRed
    title.font = UIFont.systemFont(ofSize: 19, weight: .light).rounded()

    view.host(subtitle) { label, _ in
      label.leadingAnchor.constraint(equalTo: title.leadingAnchor)
      label.trailingAnchor.constraint(equalTo: title.trailingAnchor)
      label.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4)
    }

    subtitle.text = "Describe reason before continuing?"
    subtitle.textAlignment = .center
    subtitle.font = UIFont.systemFont(ofSize: 17, weight: .light)

    view.host(picker) { picker, parent in
      picker.leadingAnchor.constraint(equalTo: subtitle.leadingAnchor)
      picker.trailingAnchor.constraint(equalTo: subtitle.trailingAnchor)
      picker.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 20)
      picker.bottomAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.bottomAnchor)
    }

    picker.collectionView.delegate = self
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public convenience init() {
    self.init(nibName: nil, bundle: nil)
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

extension InterruptionPicker: UICollectionViewDelegate {
  public func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let interruption = picker.dataSource.itemIdentifier(for: indexPath) else { return }
    callback(.interruptionTapped(interruption))
  }
}
