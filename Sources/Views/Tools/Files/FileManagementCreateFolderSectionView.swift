import SwiftUI

struct FileManagementCreateFolderSectionView: View {
    @ObservedObject var backend: FileManagementBackend
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var newFolderName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $newFolderName)
                        .autocorrectionDisabled()
                } header: {
                    Text("Folder Name")
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        backend.createFolder(name: newFolderName)
                        newFolderName = ""
                        onDismiss()
                    }
                    .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
