import ComposableArchitecture
import RingsView
import UIKit

final class RingsViewController: UIViewController {
  let store: Store<RingsViewState, RingsViewAction> = Store(initialState: .init(),
                                                            reducer: ringsViewReducer,
                                                            environment: .init(date: Date.init))

  override func loadView() {
    view = RingsView(viewStore: ViewStore(store))
  }
}

import ComposableArchitecture
let previewStore = Store<RingsViewState, RingsViewAction>(initialState: .init(),
                                                          reducer: ringsViewReducer,
                                                          environment: .init(date: Date.init))
