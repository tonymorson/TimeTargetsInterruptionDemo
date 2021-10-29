import ComposableArchitecture
import RingsView
import SwiftUI
import UIKit

struct RingsViewRepresentable: UIViewRepresentable {
  func makeUIView(context _: Context) -> UIView {
    RingsView(viewStore: ViewStore(previewStore))
  }

  func updateUIView(_: UIView, context _: Context) {}
}

struct RingsView_Preview: PreviewProvider {
  static var previews: some View {
    RingsViewRepresentable()
  }
}
