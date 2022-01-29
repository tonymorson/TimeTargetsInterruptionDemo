import SwiftUI

struct StatefulPreviewWrapper<Value, Content: View>: View {
  @State var value: Value
  var content: (Binding<Value>) -> Content

  var body: some View {
    content($value)
  }

  init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
    _value = State(wrappedValue: value)
    self.content = content
  }
}

struct StatefulListPreviewWrapper<Value, Content: View>: View {
  @State var value: Value
  var content: (Binding<Value>) -> Content

  var body: some View {
    NavigationView {
      List {
        content($value)
      }
    }
  }

  init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
    _value = State(wrappedValue: value)
    self.content = content
  }
}

struct UIKitPreview: UIViewRepresentable {
  typealias UIViewType = UIView

  let view: UIViewType

  func makeUIView(context _: Context) -> UIViewType {
    view
  }

  func updateUIView(_: UIViewType, context _: Context) {}
}
