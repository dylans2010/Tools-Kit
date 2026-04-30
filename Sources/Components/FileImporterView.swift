import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#endif

/// A reusable file importer component that wraps UIDocumentPickerViewController.
/// This component provides a full UIKit-backed document picker that can be used within SwiftUI sheets.
public struct FileImporterView: View {
    public var allowedContentTypes: [UTType]
    public var allowsMultipleSelection: Bool
    public var onDocumentsPicked: ([URL]) -> Void

    public init(
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool = false,
        onDocumentsPicked: @escaping ([URL]) -> Void
    ) {
        self.allowedContentTypes = allowedContentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onDocumentsPicked = onDocumentsPicked
    }

    public var body: some View {
        #if os(iOS)
        FileImporterInternalRepresentable(
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: allowsMultipleSelection,
            onDocumentsPicked: onDocumentsPicked
        )
        .ignoresSafeArea()
        #else
        Text("File Importer is not supported on this platform.")
        #endif
    }
}

#if os(iOS)
private struct FileImporterInternalRepresentable: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onDocumentsPicked: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowsMultipleSelection
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentsPicked: onDocumentsPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentsPicked: ([URL]) -> Void

        init(onDocumentsPicked: @escaping ([URL]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onDocumentsPicked(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onDocumentsPicked([])
        }
    }
}
#endif
