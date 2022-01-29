// import ComposableArchitecture
// import SwiftUI
// import Durations
//
// public struct SettingsView: View {
//
//  @State var workPeriod: Duration = 25.minutes
//  @State var shortBreak: Duration = 5.minutes
//  @State var longBreak: Duration = 10.minutes
//
//  @State var longBreaksFrequency: Int = 4
//  @State var dailyTarget: Int = 10
//
//  @State var pauseWorkPeriod: Bool = false
//  @State var pauseShortBreaks: Bool = false
//  @State var pauseLongBreaks: Bool = false
//
//  @State var askAboutInterruptions: Bool = true
//
//  @State var showNotifications: Bool = false
//  @State var playNotificationSounds: Bool = true
//
//  public init() {
//
//  }
////  public init(store: Store<SettingsEditorState, SettingsEditorAction>) {
////    self.store = store
////    self.viewStore = ViewStore(store)
////  }
////
////  private let store: Store<SettingsEditorState, SettingsEditorAction>
////  private let viewStore: ViewStore<SettingsEditorState, SettingsEditorAction>
//
//  public var body: some View {
//    NavigationView {
//      Form {
//        PeriodsSection(workPeriod: $workPeriod, shortBreak: $shortBreak, longBreak: $longBreak)
//          .navigationTitle("Settings")
//
//
//        Section("Sessions & Targets") {
//          LongBreaksFrequencyPicker(value: $longBreaksFrequency)
//          DailyTargetPicker(value: $dailyTarget)
//            .onReceive(NotificationCenter.default.publisher(for: UITableView.selectionDidChangeNotification)) {
//                guard let tableView = $0.object as? UITableView,
//                      let selectedRow = tableView.indexPathForSelectedRow else { return }
//
//                tableView.deselectRow(at: selectedRow, animated: true)
//            }
//        }
//
//        Section("Workflow") {
//          Toggle("Pause Before Starting Work Periods", isOn: $pauseWorkPeriod)
//          Toggle("Pause Before Starting Breaks", isOn: $pauseShortBreaks)
//          Toggle("Reset Work Period On Stop", isOn: $pauseLongBreaks)
//        }
//
//        Section("Activity Logs") {
//          Toggle("Ask About Interruptions", isOn: $askAboutInterruptions)
//        }
//
//        Section("Alerts") {
//          Toggle("Notifications", isOn: $showNotifications)
//          Toggle("Play Sound", isOn: $playNotificationSounds)
//        }
//      }
//    }
//
//  }
// }
//
// struct PeriodsSection: View {
//
//  @Binding var workPeriod: Duration
//  @Binding var shortBreak: Duration
//  @Binding var longBreak: Duration
//
//  var body: some View {
//    Section("Time Management") {
//      DurationPicker(title: "Work Period", duration: $workPeriod)
//      DurationPicker(title: "Short Break", duration: $shortBreak)
//      DurationPicker(title: "Long Break", duration: $longBreak)
//    }
//  }
//
// }
//
//
// struct SettingsView_Previews: PreviewProvider {
//  static var previews: some View {
//    SettingsView()
//  }
// }
//
// private func durationText(_ value: Duration) -> String {
//  value.asMinutes == 60
//  ? " 1 Hour"
//  : "\(String(Int(value.asMinutes))) Minutes"
// }
//
// struct DurationPicker: View {
//  var title: String
//  @Binding var duration: Duration
//
//  var body: some View {
//    NavigationLink( title) {
//      Form {
//        Section("Duration") {
//        ForEach(stride(from: 5, through: 60, by: 5).map(asMinutes), id: \.self) {
//          DurationRowView(selectedValue: $duration, duration: $0)
//            .modifier(DismissableButton())
//        }
//      }
//      }
//      .navigationTitle(title)
//      .navigationBarTitleDisplayMode(.inline)
//    }
//  }
// }
//
// struct LongBreaksForm : View {
//  @Binding var selectedValue: Int
//  @Environment(\.dismiss) var dismiss
//
//
//  var body: some View {
//    Form {
//      Section(header: Text("Session Frequency")) {
//        ForEach(2 ... 8, id: \.self) { value in
//          SessionFrequencyValueRow(selectedValue: $selectedValue, value: value)
//            .onTapGesture {
//                       selectedValue = value
//
//                dismiss()
//              }
//            }
//        }
//      }
//    }
////    .navigationBarTitleDisplayMode(.inline)
//  }
////}
//
// struct LongBreaksFrequencyPicker : View {
//  @Binding var value: Int
//
//  var body: some View {
//    NavigationLink(destination: LongBreaksForm(selectedValue: $value)) {
//
//      HStack {
//        Text("Long Breaks")
//        Spacer()
//        Text("Every \(value) Work Periods")
//          .zIndex(10)
//          .foregroundColor(.secondary)
//      }
//
//    }
////  }
////    NavigationLink("sfsdfsdf") {
////      LongBreaksForm(selectedValue: $value)
////    }
//  }
// }
//
// struct DailyTargetPicker : View {
//  @Binding var value: Int
//
//  var body: some View {
//    NavigationLink("Daily Target") {
//      Form {
//        ForEach(2 ... 10, id: \.self) {
//          IntegerValueRow(value: $0, showCheckmark: $0 == value)
//            .onReceive(NotificationCenter.default.publisher(for: UITableView.selectionDidChangeNotification)) {
//                guard let tableView = $0.object as? UITableView,
//                      let selectedRow = tableView.indexPathForSelectedRow else { return }
//
//                tableView.deselectRow(at: selectedRow, animated: true)
//            }
//        }
//
//      }
//      .navigationTitle("Daily Target")
//      .navigationBarTitleDisplayMode(.inline)
//    }
//  }
// }
//
// struct DurationRowView: View {
//  @Binding var selectedValue: Duration
//  let duration: Duration
//
//  @Environment(\.dismiss) var dismiss
//
//  var body : some View {
//
//    Button(action: {
//      selectedValue = duration
//      dismiss()
//    } ) {
//      HStack {
//        Text(durationText(duration))
//        Spacer()
//        Accessory(show: selectedValue == duration ? .checkmark : .none)
//          .foregroundColor(.accentColor)
//      }
//    }
//    .buttonStyle(.plain)
//  }
// }
//
// struct SessionFrequencyValueRow: View {
//  @Binding var selectedValue: Int
//  let value: Int
//
//  var body : some View {
//    HStack {
//      Text("Every \(value) Work Periods")
//      Spacer()
//      Accessory(show: selectedValue == value ? .checkmark : .none)
//    }
//  }
// }
//
// struct IntegerValueRow: View {
//  let value: Int
//  let showCheckmark: Bool
//
//  var body : some View {
//    HStack {
//      Text("\(value)")
//      Spacer()
//      Accessory(show: showCheckmark ? .checkmark : .none)
//    }
//  }
// }
//
// func asMinutes(minutes: Int) -> Duration {
//  minutes.minutes
// }
//
// struct Accessory: View {
//  enum Accessory { case checkmark, none }
//  let show: Accessory
//
//  var body : some View {
//    Image(systemName: show == .checkmark ? "checkmark" : "")
//  }
// }
//
// struct DismissableButton: ViewModifier {
//  func body(content: Content) -> some View {
//    content
//    .contentShape(Rectangle())
//    .buttonStyle(.plain)
//  }
// }
