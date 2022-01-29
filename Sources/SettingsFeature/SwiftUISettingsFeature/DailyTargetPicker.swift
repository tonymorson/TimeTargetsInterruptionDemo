import SwiftUI

struct DailyTargetPicker: View {
  var title: String
  @Binding var value: Int
  @State private var selection: String? = nil

  init(_ title: String, value: Binding<Int>) {
    self.title = title
    _value = value
  }

  var body: some View {
    NavigationLink(destination: DailyTargetPickerView(value: $value)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline),
      tag: "hack",
      selection: $selection) {
        ListValue(title, detail: "\(value) Work Periods")
      }.onAppear {
        self.selection = nil
      }
  }
}

struct DailyTargetPickerView: View {
  @Binding var value: Int
  @Environment(\.dismiss) var dismiss

  var body: some View {
    List {
      Section {
        Group {
          Checkmark("1 Work Period", markedValue: $value, value: 1)
          Checkmark("2 Work Periods", markedValue: $value, value: 2)
          Checkmark("3 Work Periods", markedValue: $value, value: 3)
          Checkmark("4 Work Periods", markedValue: $value, value: 4)
          Checkmark("5 Work Periods", markedValue: $value, value: 5)
          Checkmark("6 Work Periods", markedValue: $value, value: 6)
          Checkmark("7 Work Periods", markedValue: $value, value: 7)
          Checkmark("8 Work Periods", markedValue: $value, value: 8)
          Checkmark("9 Work Periods", markedValue: $value, value: 9)
          Checkmark("10 Work Periods", markedValue: $value, value: 10)
        }
        .simultaneousGesture(TapGesture().onEnded { dismiss() })
      }
    }
  }
}

// struct DailyTargetPicker_Previews: PreviewProvider {
//  static var previews: some View {
//    NavigationView {
//      List {
//        StatefulPreviewWrapper(3) { value in
//          DailyTargetPicker("Daily Target", value: value)
//        }
//      }
//    }
//  }
// }
