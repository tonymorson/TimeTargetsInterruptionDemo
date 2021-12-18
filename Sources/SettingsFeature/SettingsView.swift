// import Combine
// import ComposableArchitecture
// import Durations
// import UIKit
//
// public final class SettingsView: UITableViewController {
//  struct ViewState: Equatable {
//
//    var periodSettings: SettingsEditorState.PeriodSettings
//    var route: SettingsEditorState.Route?
//
//    enum Value: Equatable {
//      case description(String)
//      case toggle(Bool)
//    }
//
//    enum CellIdentifier: String, Equatable {
//      case workDuration
//      case shortBreakDuration
//      case longBreakDuration
//
//      case longBreakFrequency
//      case dailyTarget
//
//      case pauseWork
//      case pauseBreak
//      case resetWorkOnStop
//
//      case askAboutInterruptions
//
//      case showNotifications
//      case playNotificationSound
//    }
//
//    let sectionTitle: [String] = [
//      "Time Management",
//      "Sessions & Targets",
//      "Workflow",
//      "Activity Logs",
//      "Alerts",
//    ]
//
//    struct RowData: Equatable {
//      var identifier: CellIdentifier
//      var label: String
//      var value: Value
//
//      init(_ identifier: CellIdentifier, _ label: String, _ value: Value) {
//        self.identifier = identifier
//        self.label = label
//        self.value = value
//      }
//    }
//
//    let data: [[RowData]] = [
//      [
//        .init(.workDuration, "Work Period", .description("25 Minutes")),
//        .init(.shortBreakDuration, "Short Break", .description("5 Minutes")),
//        .init(.longBreakDuration, "Long Break", .description("15 Minutes")),
//      ],
//
//      [
//        .init(.longBreakFrequency, "Long Breaks", .description("Every 4th Break")),
//        .init(.dailyTarget, "Daily Target", .description("10 Work Periods")),
//      ],
//
//      [
//        .init(.pauseWork, "Pause Before Starting Work Periods", .toggle(true)),
//        .init(.pauseBreak, "Pause Before Starting Breaks", .toggle(false)),
//        .init(.resetWorkOnStop, "Reset Work period On Stop", .toggle(false)),
//      ],
//
//      [
//        .init(.askAboutInterruptions, "Ask About Interruptions", .toggle(true)),
//      ],
//
//      [
//        .init(.showNotifications, "Notifications", .toggle(false)),
//        .init(.playNotificationSound, "Play Sounds", .toggle(true)),
//      ],
//    ]
//
//    init(_ state: SettingsEditorState) {
//      self.route = state.route
//      self.periodSettings = state.periods
//    }
//  }
//
//  enum ViewAction: Equatable {
//    case rowTapped(ViewState.CellIdentifier)
//    case rowSwitchToggled(ViewState.CellIdentifier, Bool)
//    case pickerDismissed
//    case workPeriodDurationValueTapped(Int)
//  }
//
//  let viewStore: ViewStore<ViewState, ViewAction>
//
//  public init(store: Store<SettingsEditorState, SettingsEditorAction>) {
//
//    //    self.store = store
//
//    let scopedStore = store.scope(state: ViewState.init, action: SettingsEditorAction.init)
//    self.viewStore = ViewStore(scopedStore)
//
//    super.init(style: .insetGrouped)
//  }
//
//  private var cancellables: Set<AnyCancellable> = []
//  public override func viewDidLoad() {
//    super.viewDidLoad()
//
//    viewStore.publisher
//      .map(\.route)
//      .removeDuplicates()
//      .receive(on: DispatchQueue.main)
//      .sink { [weak self] route in
//        guard let self = self else { return }
//
//        if let _ = self.presentedViewController {
//          self.navigationController?.popToViewController(self, animated: false)
//        }
//
//        let duration: Int
//
//        switch route {
//        case .workDurationPicker: duration = 25
//        case .shortBreakDurationPicker: duration = 5
//        case .longBreakDurationPicker: duration = 10
//        case .none: duration = 0
//        }
//
//        if route != nil {
//          let picker = DurationPickerForm(markedValue: duration) { [weak self] value in
//            self?.viewStore.send(.workPeriodDurationValueTapped(value))
//            self?.viewStore.send(.pickerDismissed)
//          }
//          picker.title = route == .workDurationPicker
//          ? "Work Duration" : route == .shortBreakDurationPicker ? "Short Break" : "Long Break"
//          picker.navigationItem.largeTitleDisplayMode = .never
//          self.navigationController?.pushViewController(picker, animated: true)
//        }
//      }
//      .store(in: &cancellables)
//
//    viewStore.publisher
//      .map(\.periodSettings)
//      .removeDuplicates()
//      .receive(on: DispatchQueue.main)
//      .sink { [weak self] _ in
//        self?.tableView.reloadData()
//      }
//      .store(in: &cancellables)
//
//  }
//  public override func numberOfSections(in tableView: UITableView) -> Int {
//    return viewStore.data.count
//  }
//
//  public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    viewStore.data[section].count
//  }
//
//  public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//
//    viewStore.sectionTitle[section]
//  }
//
//  public override func willMove(toParent parent: UIViewController?) {
//    super.willMove(toParent: parent)
//
//    title = "Settings"
//    navigationController?.navigationBar.prefersLargeTitles = true
//  }
//
//  public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//    let item = viewStore.data[indexPath.section][indexPath.row]
//    let identifier = item.identifier
//    var cell = tableView.dequeueReusableCell(withIdentifier: identifier.rawValue)
//
//    if cell == nil {
//      cell = UITableViewCell()
//
//      if case .toggle = item.value {
//        let toggle = UISwitch()
//        toggle.isOn = true
//
//        toggle.addAction(UIAction {[weak self] _ in self?.viewStore.send(.rowSwitchToggled(item.identifier, toggle.isOn)) }, for: .touchUpInside)
//        cell?.accessoryView = toggle
//
//        cell?.selectionStyle = .none
//      }
//    }
//
//    var config = UIListContentConfiguration.valueCell()
//    config.prefersSideBySideTextAndSecondaryText = true
//
//    switch item.value {
//    case .description(let text):
//
//      config.secondaryText = text
//      cell?.accessoryType = .disclosureIndicator
//
//
//
//      if item.identifier == .workDuration {
//        config.secondaryText = durationText(viewStore.periodSettings.workPeriodDuration)
//        //      config.text = durationText(viewStore.periodSettings.workPeriodDuration)
//      }
//
//
//    case .toggle(let isOn):
//
//      (cell?.accessoryView as? UISwitch)?.isOn = isOn
//
//
//      //      cell?.accessories = [.customView(configuration: customAccessory)]
//    }
//
//    config.text = item.label
//
//    cell?.contentConfiguration = config
//
//    if item.identifier == .workDuration {
//      config.secondaryText = durationText(viewStore.periodSettings.workPeriodDuration)
//      //      config.text = durationText(viewStore.periodSettings.workPeriodDuration)
//    }
//
//    return cell!
//  }
//
//  public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    let item = viewStore.data[indexPath.section][indexPath.row]
//
//    viewStore.send(.rowTapped(item.identifier))
//  }
//
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
// }
//
////public final class SettingsView: UICollectionViewController {
////    enum Section: Hashable { case first, second }
////
////    var config: UICollectionLayoutListConfiguration!
////    var datasource: UICollectionViewDiffableDataSource<Section, ViewModel.CellIdentifier>!
////
////    struct ViewModel {
////        enum CellIdentifier: String {
////            case workDuration
////            case shortBreakDuration
////            case longBreakDuration
////
////            case longBreakFrequency
////            case dailyTarget
////        }
////
////        let sections: [[CellIdentifier]] = [
////            [ .workDuration, .shortBreakDuration, .longBreakDuration, ],
////            [ .longBreakFrequency, .dailyTarget, ] ]
////    }
////
////    let viewModel = ViewModel()
////
////    private func configureDataSource() {
////        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel.CellIdentifier> { (cell, indexPath, item) in
////            var content = UIListContentConfiguration.valueCell()
////
////            content.prefersSideBySideTextAndSecondaryText = true
////            content.text = item.label
////            content.secondaryText = "25 Minutes"// item.subtitle
////            content.secondaryTextProperties.color = .secondaryLabel
////
////            cell.contentConfiguration = content
////
////            let customAccessory = UICellAccessory.CustomViewConfiguration(
////              customView: UISwitch(),
////              placement: .trailing(displayed: .always))
////
////            cell.accessories = [.disclosureIndicator(), .customView(configuration: customAccessory)]
////
////
////        }
////
////
////
////
////        datasource = .init(collectionView: collectionView,
////                           cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
////            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
////        })
////
////
////        configureHeader()
////    }
////
////    func configureHeader() {
////        let header = UICollectionView.SupplementaryRegistration<TitleSupplementaryView>(elementKind: UICollectionView.elementKindSectionHeader) { (headerView, elementKind, indexPath) in
////
////            if elementKind == UICollectionView.elementKindSectionHeader {
////            if indexPath.section == 0 {
////                headerView.label.text = "TIME MANAGEMENT"
////            } else {
////            headerView.label.text = "SESSIONS & TARGETS"
////            }
////            }
////
////        }
////
////        datasource.supplementaryViewProvider = { [unowned self]
////            (collectionView, elementKind, indexPath) -> UICollectionReusableView? in
////
////            // Dequeue header view
////            return self.collectionView.dequeueConfiguredReusableSupplementary(
////                using: header, for: indexPath)
////        }
////
////
//////        { (
//////                collectionView: UICollectionView,
//////                kind: String,
//////                indexPath: IndexPath) -> UICollectionReusableView? in
//////
////////            return TitleSupplementaryView()
//////            if kind == UICollectionView.elementKindSectionHeader {
//////                return collectionView.dequeueConfiguredReusableSupplementary(using: header, for: indexPath)
////////                let header = TitleSupplementaryView()
////////               header.label.text = "Header"
////////
////////               return header
//////            } else {
//////
//////            return nil
//////            }
//////                let header: TitleSupplementaryView = collectionView.dequeueSuplementaryView(of: UICollectionView.elementKindSectionHeader, at: indexPath)
//////                header.backgroundColor = .lightGray
//////
//////                if let section = self.currentSnapshot?.sectionIdentifiers[indexPath.section] {
//////                    header.label.text = "\(section.headerItem.titleHeader)"
//////                }
//////                return header
//////            }
////        }
////
////    public convenience init(store: Store<SettingsEditorState, SettingsEditorAction>) {
////        self.init(nibName: nil, bundle: nil)
////        self.store = store
////        self.viewStore = ViewStore(store)
////    }
////
////    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
////        config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
////        config.headerMode = .supplementary
////        let layout = UICollectionViewCompositionalLayout.list(using: config)
////
////        super.init(collectionViewLayout: layout )
////    }
////
////    required init?(coder: NSCoder) {
////        fatalError("init(coder:) has not been implemented")
////    }
////
////    private var store: Store<SettingsEditorState, SettingsEditorAction>!
////    private var viewStore: ViewStore<SettingsEditorState, SettingsEditorAction>!
////
////    private func configureLayout() -> UICollectionViewLayout {
////        return UICollectionViewCompositionalLayout.list(using: config)
////    }
////
////    private func configureCollectionView() {
////        collectionView = .init(frame: view.bounds, collectionViewLayout: self.configureLayout())
////        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
////        collectionView.delegate = self
////
////        view.addSubview(collectionView)
////    }
////
////    private func applyInitialData() {
////        var snapshot = NSDiffableDataSourceSnapshot<Section, ViewModel.CellIdentifier>()
////        snapshot.appendSections([.first, .second])
////        snapshot.appendItems([.workDuration, .shortBreakDuration, .longBreakDuration,], toSection: .first)
////        snapshot.appendItems([.longBreakFrequency, .dailyTarget,], toSection: .second)
////
////        datasource.apply(snapshot, animatingDifferences: false)
////    }
////
////    public override func viewDidLoad() {
////        super.viewDidLoad()
////
////        navigationBarTitle("Settings")
////        navigationController?.navigationBar.prefersLargeTitles = true
////
//////        configureCollectionView()
////        configureDataSource()
////        applyInitialData()
////
////        collectionView.register(TitleSupplementaryView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "aa")
////    }
////
////    //  public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
////    //    if section == 1 { return "Sessions & Targets"}
////    //     return "Time Management"
////    //  }
////    //
////
////
////    //  public var body: some View {
////    //    NavigationView {
////    //      Form {
////    //        PeriodsSection(workPeriod: $workPeriod, shortBreak: $shortBreak, longBreak: $longBreak)
////    //          .navigationTitle("Settings")
////    //
////    //
////    //        Section("Sessions & Targets") {
////    //          LongBreaksFrequencyPicker(value: $longBreaksFrequency)
////    //          DailyTargetPicker(value: $dailyTarget)
////    //            .onReceive(NotificationCenter.default.publisher(for: UITableView.selectionDidChangeNotification)) {
////    //                guard let tableView = $0.object as? UITableView,
////    //                      let selectedRow = tableView.indexPathForSelectedRow else { return }
////    //
////    //                tableView.deselectRow(at: selectedRow, animated: true)
////    //            }
////    //        }
////    //
////    //        Section("Workflow") {
////    //          Toggle("Pause Before Starting Work Periods", isOn: $pauseWorkPeriod)
////    //          Toggle("Pause Before Starting Breaks", isOn: $pauseShortBreaks)
////    //          Toggle("Reset Work Period On Stop", isOn: $pauseLongBreaks)
////    //        }
////    //
////    //        Section("Activity Logs") {
////    //          Toggle("Ask About Interruptions", isOn: $askAboutInterruptions)
////    //        }
////    //
////    //        Section("Alerts") {
////    //          Toggle("Notifications", isOn: $showNotifications)
////    //          Toggle("Play Sound", isOn: $playNotificationSounds)
////    //        }
////    //      }
////    //    }
////    //
////    //  }
////}
//
////struct PeriodsSection: View {
////
////  @Binding var workPeriod: Duration
////  @Binding var shortBreak: Duration
////  @Binding var longBreak: Duration
////
////  var body: some View {
////    Section("Time Management") {
////      DurationPicker(title: "Work Period", duration: $workPeriod)
////      DurationPicker(title: "Short Break", duration: $shortBreak)
////      DurationPicker(title: "Long Break", duration: $longBreak)
////    }
////  }
////
////}
//
//
////struct SettingsView_Previews: PreviewProvider {
////  static var previews: some View {
////    SettingsView()
////  }
////}
////
// private func durationText(_ value: Duration) -> String {
//  value.asMinutes == 60
//  ? " 1 Hour"
//  : "\(String(Int(value.asMinutes))) Minutes"
// }
//
////struct DurationPicker: View {
////  var title: String
////  @Binding var duration: Duration
////
////  var body: some View {
////    NavigationLink( title) {
////      Form {
////        Section("Duration") {
////        ForEach(stride(from: 5, through: 60, by: 5).map(asMinutes), id: \.self) {
////          DurationRowView(selectedValue: $duration, duration: $0)
////            .modifier(DismissableButton())
////        }
////      }
////      }
////      .navigationTitle(title)
////      .navigationBarTitleDisplayMode(.inline)
////    }
////  }
////}
////
////struct LongBreaksForm : View {
////  @Binding var selectedValue: Int
////  @Environment(\.dismiss) var dismiss
////
////
////  var body: some View {
////    Form {
////      Section(header: Text("Session Frequency")) {
////        ForEach(2 ... 8, id: \.self) { value in
////          SessionFrequencyValueRow(selectedValue: $selectedValue, value: value)
////            .onTapGesture {
////                       selectedValue = value
////
////                dismiss()
////              }
////            }
////        }
////      }
////    }
//////    .navigationBarTitleDisplayMode(.inline)
////  }
//////}
////
////struct LongBreaksFrequencyPicker : View {
////  @Binding var value: Int
////
////  var body: some View {
////    NavigationLink(destination: LongBreaksForm(selectedValue: $value)) {
////
////      HStack {
////        Text("Long Breaks")
////        Spacer()
////        Text("Every \(value) Work Periods")
////          .zIndex(10)
////          .foregroundColor(.secondary)
////      }
////
////    }
//////  }
//////    NavigationLink("sfsdfsdf") {
//////      LongBreaksForm(selectedValue: $value)
//////    }
////  }
////}
////
////struct DailyTargetPicker : View {
////  @Binding var value: Int
////
////  var body: some View {
////    NavigationLink("Daily Target") {
////      Form {
////        ForEach(2 ... 10, id: \.self) {
////          IntegerValueRow(value: $0, showCheckmark: $0 == value)
////            .onReceive(NotificationCenter.default.publisher(for: UITableView.selectionDidChangeNotification)) {
////                guard let tableView = $0.object as? UITableView,
////                      let selectedRow = tableView.indexPathForSelectedRow else { return }
////
////                tableView.deselectRow(at: selectedRow, animated: true)
////            }
////        }
////
////      }
////      .navigationTitle("Daily Target")
////      .navigationBarTitleDisplayMode(.inline)
////    }
////  }
////}
////
////struct DurationRowView: View {
////  @Binding var selectedValue: Duration
////  let duration: Duration
////
////  @Environment(\.dismiss) var dismiss
////
////  var body : some View {
////
////    Button(action: {
////      selectedValue = duration
////      dismiss()
////    } ) {
////      HStack {
////        Text(durationText(duration))
////        Spacer()
////        Accessory(show: selectedValue == duration ? .checkmark : .none)
////          .foregroundColor(.accentColor)
////      }
////    }
////    .buttonStyle(.plain)
////  }
////}
////
////struct SessionFrequencyValueRow: View {
////  @Binding var selectedValue: Int
////  let value: Int
////
////  var body : some View {
////    HStack {
////      Text("Every \(value) Work Periods")
////      Spacer()
////      Accessory(show: selectedValue == value ? .checkmark : .none)
////    }
////  }
////}
////
////struct IntegerValueRow: View {
////  let value: Int
////  let showCheckmark: Bool
////
////  var body : some View {
////    HStack {
////      Text("\(value)")
////      Spacer()
////      Accessory(show: showCheckmark ? .checkmark : .none)
////    }
////  }
////}
////
////func asMinutes(minutes: Int) -> Duration {
////  minutes.minutes
////}
////
////struct Accessory: View {
////  enum Accessory { case checkmark, none }
////  let show: Accessory
////
////  var body : some View {
////    Image(systemName: show == .checkmark ? "checkmark" : "")
////  }
////}
////
////struct DismissableButton: ViewModifier {
////  func body(content: Content) -> some View {
////    content
////    .contentShape(Rectangle())
////    .buttonStyle(.plain)
////  }
////}
//
//// MARK: SwiftUI Preview
// #if DEBUG
// import SwiftUI
//
// struct ContentViewControllerContainerView: UIViewControllerRepresentable {
//  typealias UIViewControllerType = UINavigationController
//
//  func makeUIViewController(context: Context) -> UIViewControllerType {
//
//    let initialValue = SettingsEditorState(appearance: .dark,
//                                           neverSleep: true,
//                                           notifications: .init(),
//                                           periods: .init(periodDuration: 25.minutes,
//                                                          shortBreakDuration: 5.minutes,
//                                                          longBreakDuration: 10.minutes,
//                                                          longBreakFrequency: 4,
//                                                          dailyTarget: 10,
//                                                          pauseBeforeStartingWorkPeriods: true,
//                                                          pauseBeforeStartingBreaks: true,
//                                                          resetWorkPeriodOnStop: true), route: nil)
//
//
//    let store = Store(initialState: initialValue, reducer: reducer, environment: ())
//
//    let nv = UINavigationController(rootViewController: SettingsView(store: store))
//    return nv
//    //        return SettingsView(store: store)
//  }
//  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
// }
// struct ContentViewController_Previews: PreviewProvider {
//  static var previews: some View {
//    ContentViewControllerContainerView().colorScheme(.light).previewInterfaceOrientation(.portrait) // or .dark
//  }
// }
// #endif
//
////extension SettingsView.ViewModel.CellIdentifier {
////    var label: String {
////        switch self {
////        case .workDuration: return "Work Period"
////        case .shortBreakDuration: return "Short Break"
////        case .longBreakDuration: return "Long Break"
////        case .longBreakFrequency:
////            return "Long Breaks"
////        case .dailyTarget:
////            return "Daily Target"
////        }
////    }
////}
//
////class TitleSupplementaryView: UICollectionReusableView {
////
////    let label = UILabel()
////    static let reuseIdentifier = "title-supplementary-reuse-identifier"
////
////    override init(frame: CGRect) {
////        super.init(frame: frame)
////        configure()
////    }
////    required init?(coder: NSCoder) {
////        fatalError()
////    }
////}
////
////extension TitleSupplementaryView {
////    func configure() {
////        addSubview(label)
////        label.translatesAutoresizingMaskIntoConstraints = false
////        label.adjustsFontForContentSizeCategory = true
////        let inset = CGFloat(5)
////        NSLayoutConstraint.activate([
////            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset * 4),
////            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
////            label.topAnchor.constraint(equalTo: topAnchor, constant: inset * 3),
////            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
////            ])
////        label.font = UIFont.systemFont(ofSize: 13)
////        label.textColor = .secondaryLabel
////    }
////}
//
// extension SettingsEditorAction {
//  init(action: SettingsView.ViewAction) {
//    switch action {
//
//    case .rowTapped(.workDuration):
//      self = .workDurationTapped(15.minutes)
//
//    case .rowTapped(.shortBreakDuration):
//      self = .shortBreakDurationTapped(5.minutes)
//
//    case .rowTapped(.longBreakDuration):
//      self = .longBreakDurationTapped(10.minutes)
//
//    case let .rowSwitchToggled(.showNotifications, isOn):
//      self = .notification(.showNotificationsToggled(isOn))
//
//    case let .rowSwitchToggled(.playNotificationSound, isOn):
//      self = .notification(.showNotificationsToggled(isOn))
//
//    case let .rowSwitchToggled(.pauseWork, isOn):
//      self = .pauseBeforeWorkPeriodTapped(isOn)
//
//    case let .rowSwitchToggled(.pauseBreak, isOn):
//      self = .notification(.showNotificationsToggled(isOn))
//
//    case let .rowSwitchToggled(.resetWorkOnStop, isOn):
//      self = .notification(.showNotificationsToggled(isOn))
//
//    case let .rowSwitchToggled(.askAboutInterruptions, isOn):
//      self = .notification(.showNotificationsToggled(isOn))
//
//    case .pickerDismissed:
//      self = .pickerDismissed
//
//    case .workPeriodDurationValueTapped(let value):
//      self = .workDurationTapped2(value.minutes)
//
//    default:
//      fatalError()
//    }
//  }
// }
//
// final class DurationPickerForm : UITableViewController {
//
//  let data = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
//  var markedValue: Int
//
//  var onDeinit: (Int) -> ()
//
//  deinit {
////    onDeinit(markedValue)
//  }
//
//  override func viewWillDisappear(_ animated: Bool) {
//    super.viewWillDisappear(animated)
//    onDeinit(markedValue)
//  }
//
//  init(markedValue: Int, onDeinit: @escaping (Int) -> Void) {
//    self.markedValue = markedValue
//    self.onDeinit = onDeinit
//    super.init(style: .insetGrouped)
//  }
//
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//
//  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//    "Duration"
//  }
//
//  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    data.count
//  }
//
//  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    markedValue = data[indexPath.row]
//    tableView.reloadData()
//    navigationController?.popViewController(animated: true)
//  }
//
//  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//    let cell = UITableViewCell(style: .value1, reuseIdentifier: String(indexPath.row))
//
//    cell.textLabel?.text  = "\(data[indexPath.row]) Minutes"
//    cell.accessoryView = markedValue == data[indexPath.row]
//    ? UIImageView(image: UIImage(systemName: "checkmark"))
//    : nil
//
//    return cell
//  }
// }
