import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: String
    var onEditingChanged: (() -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = true
        textView.allowsEditingTextAttributes = true
        textView.backgroundColor = .clear
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.onEditingChanged?()
        }
    }
}
