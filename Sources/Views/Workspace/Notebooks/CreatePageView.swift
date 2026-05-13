import SwiftUI

struct CreatePageView: View {
    let folderID: UUID
    let notebookID: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared
    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter Page Title", text: $title)
                } header: {
                    Text("Page Title")
                }
            }
            .navigationTitle("New Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        manager.addPage(to: folderID, in: notebookID, title: t.isEmpty ? "Untitled Page" : t)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }
}
