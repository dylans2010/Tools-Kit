#if canImport(UIKit)
import SwiftUI
import UIKit

/// Legacy UIKit wrapper kept for Xcode target compatibility.
final class RepoDetailViewController: UIViewController {
    private let repository: GitHubRepository

    init(repository: GitHubRepository) {
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor @available(*, unavailable)
    required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingController = UIHostingController(rootView: RepoDetailView(repository: repository))
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}

#endif
