#if canImport(UIKit)
import SwiftUI
import UIKit

/// Legacy UIKit wrapper kept for Xcode target compatibility.
final class RepoListViewController: UIHostingController<RepoListView> {
    init() {
        super.init(rootView: RepoListView())
    }

    @MainActor @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
