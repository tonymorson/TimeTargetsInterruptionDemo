import Foundation
import SwiftUIKit
import Timeline
import UIKit

struct Section: Hashable {}

public final class InterruptionPickerView: UIView {
  var dataSource: UICollectionViewDiffableDataSource<Section, Interruption>!

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
    }.selectedSegmentIndex = 0

    let layout = ColumnFlowLayout()
    layout.minimumInteritemSpacing = 0

    let collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)

    host(collectionView) { collectionView, parent in
      collectionView.leadingAnchor.constraint(equalTo: segmentedControl.leadingAnchor)
      collectionView.trailingAnchor.constraint(equalTo: segmentedControl.trailingAnchor)
      collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20)
      collectionView.bottomAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.bottomAnchor)
    }.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "Cell")

    dataSource = UICollectionViewDiffableDataSource<Section, Interruption>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in

      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        as! UICollectionViewListCell

      var config = cell.defaultContentConfiguration()
      config.image = UIImage(systemName: itemIdentifier.imageName)
      config.text = itemIdentifier.conciseTitle

      cell.contentConfiguration = config

      return cell
    }

    collectionView.dataSource = dataSource

    var snapshot = NSDiffableDataSourceSnapshot<Section, Interruption>()
    let section = Section()
    snapshot.appendSections([section])
    snapshot.appendItems(Interruption.allCases, toSection: section)
    dataSource.apply(snapshot)
  }

  lazy var general: UIAction = {
    let action = UIAction(title: "General") { _ in
      var snapshot = NSDiffableDataSourceSnapshot<Section, Interruption>()
      let section = Section()
      snapshot.appendSections([section])
      snapshot.appendItems(Interruption.general, toSection: section)
      self.dataSource.apply(snapshot)
    }

    return action
  }()

  lazy var more: UIAction = {
    let action = UIAction(title: "More") { _ in
      var snapshot = NSDiffableDataSourceSnapshot<Section, Interruption>()
      let section = Section()
      snapshot.appendSections([section])
      snapshot.appendItems(Interruption.more, toSection: section)
      self.dataSource.apply(snapshot)
    }

    return action
  }()

  lazy var all: UIAction = {
    let action = UIAction(title: "All") { _ in
      var snapshot = NSDiffableDataSourceSnapshot<Section, Interruption>()
      let section = Section()
      snapshot.appendSections([section])
      snapshot.appendItems(Interruption.allCases, toSection: section)
      self.dataSource.apply(snapshot)
    }

    return action
  }()
}

class ColumnFlowLayout: UICollectionViewFlowLayout {
  override func prepare() {
    super.prepare()

    guard let collectionView = collectionView else { return }

    let availableWidth = collectionView.bounds.inset(by: collectionView.layoutMargins).width
    let maxNumColumns = Int(availableWidth / 170)
    let cellWidth = (availableWidth / CGFloat(maxNumColumns)).rounded(.down)

    itemSize = CGSize(width: cellWidth, height: 44)
    sectionInset = UIEdgeInsets(top: minimumInteritemSpacing, left: 0.0, bottom: 0.0, right: 0.0)
    sectionInsetReference = .fromSafeArea
  }
}
