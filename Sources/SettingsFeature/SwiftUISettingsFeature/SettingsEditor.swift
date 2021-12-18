import SwiftUI

public struct AppSettings: Equatable {
  public var workDuration: Int = 25
  public var shortBreak: Int = 5
  public var longBreak: Int = 10
  public var longBreaksFrequency: Int = 4
  public var dailyTarget: Int = 10
  public var pauseBeforeEachWorkPeriod: Bool = true
  public var pauseBeforeEachBreak: Bool = true
  public var resetWorkPeriodOnStop: Bool = true
  public var askAboutInteruptions: Int? = 3
  // public   var notificationSettings: NotificationsEditorState = .init()
  public var theme: Theme?
  public var neverSleep: Bool = true
  public var showAlert: Bool = false
}

public final class AppState: ObservableObject {
  @Published public var settings = AppSettings()

  init() {
//    Timer.publish(every: 1.0, on: .main, in: .common)
//      .autoconnect()
//      .assign(to: &$timestamp)
  }
}

public struct SettingsEditor: View {
  @ObservedObject public var value: AppState

  public init() {
    value = AppState()
  }

  public var body: some View {
    NavigationView {
      List {
        Section(header: Text("Time Management")) {
          DurationPicker(label: "Work Duration", value: $value.settings.workDuration)
          DurationPicker(label: "Short Break", value: $value.settings.shortBreak)
          DurationPicker(label: "Long Break", value: $value.settings.longBreak)
        }

        Section(header: Text("Sessions & Targets")) {
          LongBreaksFrequencyPicker("Long Breaks", value: $value.settings.longBreaksFrequency)
          DailyTargetPicker("Daily Target", value: $value.settings.dailyTarget)
        }

        Section(header: Text("Workflow")) {
          Toggle("Pause Before Starting Work Periods", isOn: $value.settings.pauseBeforeEachWorkPeriod)
          Toggle("Pause Before Starting Breaks", isOn: $value.settings.pauseBeforeEachBreak)
          Toggle("Reset Work Period On Stop", isOn: $value.settings.resetWorkPeriodOnStop)
        }

        Section(header: Text("Activity Logs")) {
          SignificantPausesPicker("Log Pauses", value: $value.settings.askAboutInteruptions)
        }

//        Section(header: Text("Alerts")) {
//          NotificationsPicker("Notifications", value: $value.settings.notificationSettings)
//
//          if value.notificationSettings.isNotificationsEnabled {
//            Toggle("Play Sound", isOn: $value.settings.notificationSettings.isPlayingNotificationSounds)
//          }
//        }
//        .animation(.default, value: value.notificationSettings.isPlayingNotificationSounds)

        Section(header: Text("Appearance")) {
          ThemePicker("Theme", value: $value.settings.theme)
        }

        Section(header: Text("Power")) {
          Toggle("Never Sleep", isOn: $value.settings.neverSleep)
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.large)
//      .navigationBarItems(leading: Button("Cancel", role: .cancel) { value.showAlert = false })
//      .navigationBarItems(trailing: Button("Done", role: .none) { value.showAlert = false })
    }
    .navigationViewStyle(.stack)

//    .preferredColorScheme(themeForSetting(value.settings.theme))
  }
}

// struct SettingsEditor_Previews: PreviewProvider {
//  static var previews: some View {
//    StatefulPreviewWrapper(AppSettings(), content: SettingsEditor.init)
//  }
// }
