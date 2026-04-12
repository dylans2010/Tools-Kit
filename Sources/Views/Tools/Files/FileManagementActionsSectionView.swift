import SwiftUI

struct FileManagementActionsSectionView: View {
    @ObservedObject var backend: FileManagementBackend
    @Binding var showingImporter: Bool

    var body: some View {
        HStack {
            Button("Import Files") {
                showingImporter = true
            }
            .buttonStyle(.borderedProminent)

            Button {
                Task { await backend.summarizeSelectedFile() }
            } label: {
                if backend.isSummarizing {
                    ProgressView()
                } else {
                    Text("AI Summary")
                }
            }
            .buttonStyle(.bordered)
            .disabled(backend.selectedItem == nil)
        }
    }
}
