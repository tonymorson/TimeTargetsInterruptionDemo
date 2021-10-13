import Foundation
import SwiftUIKit
import Timeline
import UIKit

/// Represents an action a user can take when interacting with an InterruptionPickerView
public enum InterruptionPickerAction: Equatable, Codable {
  case dismissed
  case interruptionTapped(Interruption)
}

/// Represents the current state of an InterruptionPickerView.
public struct InterruptionPickerState: Equatable {
  // The text being displayed in the drag bar area.
  var title: String = ""
  var subtitle: String = ""

  // The segment currently selected in the scope bar.
  var scopeIdentifier: Int = 0

  // Creates an instance of this struct.
  public init(scopeIdentifier: Int = 0, title: String, subtitle: String) {
    // Set the text items.
    self.title = title
    self.subtitle = subtitle

    // Set the scope identifier.
    self.scopeIdentifier = scopeIdentifier
  }
}

@MainActor
public final class InterruptionPickerViewController: UIViewController {
  public lazy var actions: AsyncStream<InterruptionPickerAction> = {
    AsyncStream(InterruptionPickerAction.self) { continuation in
      self.continuation = continuation
    }
  }()

  // MARK: - Public Methods

  // Constructs an instance of this view controller.
  @MainActor
  public convenience init(state: InterruptionPickerState) {
    self.init(nibName: nil, bundle: nil)

    titleTextView.text = state.title
    subtitleTextView.text = state.subtitle
  }

  // MARK: - Overrides

  // Called by the system. Do not call this method directly.
  override public func viewDidLoad() {
    // Style the background color of the main view.
    view.backgroundColor = .systemBackground

    // Style the font and colors of the top title and subtitle views.
    titleTextView.textAlignment = .center
    titleTextView.textColor = .systemRed
    titleTextView.font = UIFont.systemFont(ofSize: 19, weight: .light).rounded()

    subtitleTextView.textAlignment = .center
    subtitleTextView.font = UIFont.systemFont(ofSize: 17, weight: .light)

    // Compose all the subviews vertically inside this controller's view.
    view.host(titleTextView) { label, view in
      label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
      label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
      label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
    }

    view.host(subtitleTextView) { label, _ in
      label.leadingAnchor.constraint(equalTo: titleTextView.leadingAnchor)
      label.trailingAnchor.constraint(equalTo: titleTextView.trailingAnchor)
      label.topAnchor.constraint(equalTo: titleTextView.bottomAnchor, constant: 4)
    }

    view.host(interruptionPickerView) { picker, view in
      picker.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
      picker.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
      picker.topAnchor.constraint(equalTo: subtitleTextView.bottomAnchor, constant: 12)
      picker.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    }

    // Set ourselves as the grid view delegate so we can respond to user selections.
    interruptionPickerView.collectionView.delegate = self
  }

  // Called by the system. Do not call this method directly.
  override public func viewDidDisappear(_ animated: Bool) {
    
    // Check to see if we are being permmnently dismissed and if so,
    // send a final message to the client and clean up the continuation.
    if isBeingDismissed {
      continuation?.yield(.dismissed)
      continuation?.finish()
    }
    
    // Call super as required by design contract.
    super.viewDidDisappear(animated)
  }

  // MARK: - Private State

  private var continuation: AsyncStream<InterruptionPickerAction>.Continuation?
  private let interruptionPickerView = InterruptionPickerView()
  private let subtitleTextView = UILabel()
  private let titleTextView = UILabel()

  // MARK: - Private Methods

  @MainActor
  private init() {
    super.init(nibName: nil, bundle: nil)
  }

  override private init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  @available(*, unavailable)
  internal required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Internal Classes

final class ColumnFlowLayout: UICollectionViewFlowLayout {
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

/// A grid of cells containing an interruption name and an associated icon for user selection.
final class InterruptionPickerView: UIView {
  struct Section: Hashable {}

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

    host(segmentedControl) { control, view in
      control.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10)
      control.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
      control.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
    }
    .selectedSegmentIndex = 0

    let layout = ColumnFlowLayout()
    //    layout.scrollDirection = .horizontal
    layout.minimumInteritemSpacing = 0

    collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)

    host(collectionView) { collectionView, view in
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
      collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20)
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    }

    let reg = UICollectionView.CellRegistration<UICollectionViewListCell, Interruption> { cell, _, interruption in

      var contentConfiguration = cell.defaultContentConfiguration()
      //      config.textProperties.numberOfLines = 2
      contentConfiguration.image = UIImage(systemName: interruption.imageName)
      contentConfiguration.text = interruption.conciseTitle
      //      contentConfiguration.imageToTextPadding = 10
      contentConfiguration.textProperties.numberOfLines = 1
      //      contentConfiguration.textProperties.adjustsFontSizeToFitWidth = true

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

// MARK: - Internal Extensions

extension InterruptionPickerViewController: UICollectionViewDelegate {
  public func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let interruption = interruptionPickerView.dataSource.itemIdentifier(for: indexPath) else { return }
    continuation?.yield(.interruptionTapped(interruption))
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
