import SwiftUI

struct ListValue: View {
  var title: String
  var detail: String

  init(_ title: String, detail: String) {
    self.title = title
    self.detail = detail
  }

  var body: some View {
    HStack {
      Text(title)
      Spacer()
      Text(detail)
        .foregroundColor(.secondary)
    }
  }
}
