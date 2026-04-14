import SwiftUI

struct CreateFolderView: View {
    let notebookID: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Folder Name") {
                    TextField("Enter Folder Name", text: $name)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        manager.addFolder(to: notebookID, name: n.isEmpty ? "New Folder" : n)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }
}
