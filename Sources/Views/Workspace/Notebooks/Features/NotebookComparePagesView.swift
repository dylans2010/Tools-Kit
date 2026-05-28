import SwiftUI

struct NotebookComparePagesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared

    @State private var leftPage: NotebookPage?
    @State private var rightPage: NotebookPage?

    @State private var selectingLeft = false
    @State private var selectingRight = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Left Side
                    VStack {
                        if let page = leftPage {
                            pageHeader(page: page) { leftPage = nil }
                            Divider()
                            ScrollView {
                                Text(page.content)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            Button("Select Left Page") { selectingLeft = true }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemGray6))
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    // Right Side
                    VStack {
                        if let page = rightPage {
                            pageHeader(page: page) { rightPage = nil }
                            Divider()
                            ScrollView {
                                Text(page.content)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            Button("Select Right Page") { selectingRight = true }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemGray6))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                if leftPage != nil && rightPage != nil {
                    diffSummary
                }
            }
            .navigationTitle("Compare Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $selectingLeft) {
                PagePicker { page in leftPage = page }
            }
            .sheet(isPresented: $selectingRight) {
                PagePicker { page in rightPage = page }
            }
        }
    }

    private func pageHeader(page: NotebookPage, onClear: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(page.title)
                    .font(.headline)
                Text("Last Updated \(page.updatedAt, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var diffSummary: some View {
        VStack {
            Divider()
            HStack {
                let leftWords = leftPage?.content.split(separator: " ").count ?? 0
                let rightWords = rightPage?.content.split(separator: " ").count ?? 0
                let diff = abs(leftWords - rightWords)

                Label("\(diff) word difference", systemImage: "arrow.left.and.right")
                    .font(.caption.bold())
                Spacer()
                Button("Sync Content") {
                    // Placeholder for sync logic
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}

struct PagePicker: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared
    let onSelect: (NotebookPage) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(manager.notebooks) { notebook in
                    Section(notebook.name) {
                        ForEach(notebook.folders) { folder in
                            ForEach(folder.pages) { page in
                                Button(page.title) {
                                    onSelect(page)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Page")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
