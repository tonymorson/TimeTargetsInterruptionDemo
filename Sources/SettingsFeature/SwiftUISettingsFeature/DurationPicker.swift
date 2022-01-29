import SwiftUI

struct DurationPicker: View {
  let label: String
  @Binding var value: Int
  @State private var selection: String? = nil

  var body: some View {
    NavigationLink(destination: DurationPickerList(value: $value)
      .navigationTitle(label)
      .navigationBarTitleDisplayMode(.inline),
      tag: "hack",
      selection: $selection) {
        ListValue(label, detail: "\(value) Minutes")
          .onAppear { self.selection = nil }
      }
  }
}

struct DurationPickerList: View {
  @Binding var value: Int
  @Environment(\.dismiss) var dismiss

  var body: some View {
    List {
      Section("DURATION") {
        ForEach(Array(stride(from: 5, through: 60, by: 5)), id: \.self) { duration in
          let description = duration == 60 ? "1 Hour" : "\(duration) Minutes"
          Checkmark(description, markedValue: $value, value: duration)
        }
        .simultaneousGesture(TapGesture().onEnded { dismiss() })
      }
    }
  }
}

struct ValueListCell_Previews: PreviewProvider {
  static var previews: some View {
    StatefulPreviewWrapper((25, 5, 10)) { values in
      NavigationView {
        HStack {
          List {
            DurationPicker(label: "Work Period", value: values.0)
            DurationPicker(label: "Short Break", value: values.1)
            DurationPicker(label: "Long Break", value: values.2)
          }
        }
      }
    }

    StatefulPreviewWrapper(10) {
      DurationPickerList(value: $0)
    }
  }
}
