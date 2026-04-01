import Foundation
import SwiftUI

class ClipboardManagerBackend: ObservableObject {
    @Published var clipboardContent = ""

    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }

    func pasteFromClipboard() {
        clipboardContent = UIPasteboard.general.string ?? ""
    }
}
