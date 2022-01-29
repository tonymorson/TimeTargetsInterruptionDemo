import SwiftUI

public enum Theme { case light, dark }

public extension UIUserInterfaceStyle {
   init(theme: Theme) {
    switch theme {
    case .dark: self = .dark
    case .light: self = .light
    }
  }
}

struct ThemePicker: View {
  var title: String
  @Binding var setting: Theme?
  @State private var selection: String? = nil

  init(_ title: String, value: Binding<Theme?>) {
    self.title = title
    _setting = value
  }

  var body: some View {
    NavigationLink(destination: ThemePickerList(setting: $setting)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline),
      tag: "hack!",
      selection: $selection) {
        ListValue(title, detail: describe(setting))
          .onAppear { self.selection = nil }
      }
  }
}


struct ThemePickerList: View {
  @Binding var setting: Theme?
  @Environment(\.dismiss) var dismiss

  var body: some View {
    List {
      Section {
        Group {
          Checkmark(describe(.dark), markedValue: $setting, value: .dark)
          Checkmark(describe(.light), markedValue: $setting, value: .light)
          Checkmark(describe(nil), markedValue: $setting, value: nil)
        }
        .simultaneousGesture(TapGesture().onEnded { dismiss() })
      }
    }
  }
}

func describe(_ theme: Theme?) -> String {
  switch theme {
  case .some(.dark): return "Dark"
  case .some(.light): return "Light"
  case .none: return "Auto"
  }
}

struct Checkmark<Value, Label>: View where Value: Equatable, Label: View {
  var label: Label
  @Binding var markedValue: Value
  var value: Value

  public init(_ title: String, markedValue: Binding<Value>, value: Value) where Label == Text {
    label = Text(title)
    _markedValue = markedValue
    self.value = value
  }

  var body: some View {
    HStack {
      label
      Spacer()
      Image(systemName: "checkmark")
        .opacity(markedValue == value ? 1 : 0)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      markedValue = value
    }
  }
}

struct ThemePicker_Previews: PreviewProvider {
  static var previews: some View {
    StatefulPreviewWrapper(.some(Theme.light)) { theme in
      NavigationView {
        List {
          ThemePicker("Theme", value: theme)
        }
      }
    }

    StatefulPreviewWrapper(Theme.light) {
      ThemePickerList(setting: $0)
    }
  }
}
