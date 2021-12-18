import Combine
import SettingsEditor
import SettingsFeature
import SwiftUI
import UIKit

// let initialValue = SettingsEditorState(appearance: .dark,
//                                       neverSleep: true,
//                                       notifications: .init(),
//                                       periods: .init(periodDuration: 25.minutes,
//                                                      shortBreakDuration: 5.minutes,
//                                                      longBreakDuration: 10.minutes,
//                                                      longBreakFrequency: 4,
//                                                      dailyTarget: 10,
//                                                      pauseBeforeStartingWorkPeriods: true,
//                                                      pauseBeforeStartingBreaks: true,
//                                                      resetWorkPeriodOnStop: true))

// let settings = CurrentValueSubject<SettingsEditorState, Never>(initialValue)

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var cancellables: Set<AnyCancellable> = []
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let scene = (scene as? UIWindowScene) else { return }

    let editor = SettingsFeature.SettingsView()
//    let editor = SettingsEditor(state: settings.eraseToAnyPublisher())
//
//    let actions = editor.sentActions
//
//    actions.sink { action in
//      settingsEditorReducer(state: &settings.value, action: action)
//    }
//    .store(in: &cancellables)

    let window = UIWindow(windowScene: scene)
    window.rootViewController = UIHostingController(rootView: editor)
//    window.rootViewController = editor
    window.makeKeyAndVisible()

//    window.overrideUserInterfaceStyle = .dark

    self.window = window
  }
}
