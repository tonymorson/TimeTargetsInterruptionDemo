import ComposableArchitecture
import PromptsFeature
import UIKit

final class PreviewController: UIViewController {
  let store: Store<PromptsState, PromptsAction> = Store(initialState: .init(),
                                                        reducer: promptsReducer,
                                                        environment: .init(date: Date.init, scheduler: .main))

  override func loadView() {
    view = PromptsView(store: store)
  }
}
