import Foundation
import UIKit

class TextProxyManager: ObservableObject {
    weak var proxy: UITextDocumentProxy?
    private var debouncer = Debouncer(delay: 0.3)

    @Published var currentText: String = ""

    init(proxy: UITextDocumentProxy?) {
        self.proxy = proxy
        self.currentText = proxy?.documentContextBeforeInput ?? ""
    }

    func updateProxy(with text: String) {
        guard let proxy = proxy else { return }

        // Remove existing text (simple implementation)
        while proxy.hasText {
            proxy.deleteBackward()
        }

        proxy.insertText(text)
        currentText = text
    }

    func insertText(_ text: String) {
        proxy?.insertText(text)
        currentText += text
    }

    func deleteBackward() {
        proxy?.deleteBackward()
        if !currentText.isEmpty {
            currentText.removeLast()
        }
    }

    func syncSnapshot(completion: @escaping (String) -> Void) {
        debouncer.debounce { [weak self] in
            let text = self?.proxy?.documentContextBeforeInput ?? ""
            self?.currentText = text
            completion(text)
        }
    }
}
