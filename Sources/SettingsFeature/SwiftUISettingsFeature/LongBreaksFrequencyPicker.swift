import SwiftUI

struct LongBreaksFrequencyPicker: View {
  var title: String
  @Binding var value: Int
  @State private var selection: String? = nil

  init(_ title: String, value: Binding<Int>) {
    self.title = title
    _value = value
  }

  var body: some View {
    NavigationLink(destination: LongBreaksFrequencyPickerView(value: $value)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline),
      tag: "Hack",
      selection: $selection) {
        ListValue(title, detail: "Every \(value) Work Periods")
          .onAppear { self.selection = nil }
      }
  }
}

struct LongBreaksFrequencyPickerView: View {
  @Binding var value: Int
  @Environment(\.dismiss) var dismiss

  var body: some View {
    List {
      Section("Long Breaks Frequency") {
        Group {
          Checkmark("Every 2 Work Periods", markedValue: $value, value: 2)
          Checkmark("Every 3 Work Periods", markedValue: $value, value: 3)
          Checkmark("Every 4 Work Periods", markedValue: $value, value: 4)
          Checkmark("Every 5 Work Periods", markedValue: $value, value: 5)
          Checkmark("Every 6 Work Periods", markedValue: $value, value: 6)
          Checkmark("Every 7 Work Periods", markedValue: $value, value: 7)
          Checkmark("Every 8 Work Periods", markedValue: $value, value: 8)
        }
        .simultaneousGesture(TapGesture().onEnded { dismiss() })
      }
    }
    .navigationTitle("Long Breaks")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LongBreaksFrequencyPicker_Previews: PreviewProvider {
  static var previews: some View {
    StatefulPreviewWrapper(2) { value in
      NavigationView {
        List {
          LongBreaksFrequencyPicker("Long Breaks", value: value)
        }
      }
    }

    StatefulPreviewWrapper(2) {
      LongBreaksFrequencyPickerView(value: $0)
    }
  }
}
