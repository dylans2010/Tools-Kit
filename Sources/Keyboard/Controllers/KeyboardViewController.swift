import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private var proxyManager: TextProxyManager?
    private var hostingController: UIHostingController<KeyboardRootView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.proxyManager = TextProxyManager(proxy: self.textDocumentProxy)
        setupSwiftUI()
    }

    private func setupSwiftUI() {
        guard let proxyManager = self.proxyManager else { return }

        let rootView = KeyboardRootView(proxyManager: proxyManager)
        let controller = UIHostingController(rootView: rootView)
        self.hostingController = controller

        addChild(controller)
        view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear

        NSLayoutConstraint.activate([
            controller.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            controller.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        controller.didMove(toParent: self)
    }

    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }

    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        proxyManager?.syncSnapshot { [weak self] text in
            // Handle snapshot update in RootView if needed via published property
        }
    }

    override var hasFullAccess: Bool {
        return super.hasFullAccess
    }
}
