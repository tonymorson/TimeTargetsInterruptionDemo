import SwiftUI

struct SignificantPausesPicker: View {
  var title: String
  @Binding var value: Int?
  @State private var selection: String? = nil

  init(_ title: String, value: Binding<Int?>) {
    self.title = title
    _value = value
  }

  var body: some View {
    NavigationLink(destination: SignificantPausesPickerView(value: $value)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline),
      tag: "hack!",
      selection: $selection) {
        ListValue("Log Pauses", detail: value == 0
          ? "Always"
          : value == nil ? "Never" : "Longer Than \(value!) Seconds")
      }
      .onAppear { self.selection = nil }
  }
}

struct SignificantPausesPickerView: View {
  @Binding var value: Int?
  @Environment(\.dismiss) var dismiss

  var body: some View {
    List {
      Section {
        Group {
          Checkmark("Always", markedValue: $value, value: 0)
          Checkmark("Longer Than 1 Second", markedValue: $value, value: 1)
          Checkmark("Longer Than 2 Seconds", markedValue: $value, value: 2)
          Checkmark("Longer Than 3 Seconds", markedValue: $value, value: 3)
          Checkmark("Longer Than 4 Seconds", markedValue: $value, value: 4)
          Checkmark("Longer Than 5 Seconds", markedValue: $value, value: 5)
          Checkmark("Longer Than 10 Seconds", markedValue: $value, value: 10)
          Checkmark("Longer Than 15 Seconds", markedValue: $value, value: 15)
          Checkmark("Longer Than 30 Seconds", markedValue: $value, value: 30)
          Checkmark("Never", markedValue: $value, value: nil)
        }
        .simultaneousGesture(TapGesture().onEnded { dismiss() })
      }
    }
  }
}

struct SignificantPausesPicker_Previews: PreviewProvider {
  static var previews: some View {
    StatefulPreviewWrapper(1) { value in
      NavigationView {
        List {
          SignificantPausesPicker("Log Pauses", value: value)
        }
      }
    }

    StatefulPreviewWrapper(1) { value in
      SignificantPausesPickerView(value: value)
    }
  }
}
