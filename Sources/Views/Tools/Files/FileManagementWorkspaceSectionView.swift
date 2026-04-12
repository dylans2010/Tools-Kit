import SwiftUI

struct FileManagementWorkspaceSectionView: View {
    @ObservedObject var backend: FileManagementBackend

    var body: some View {
        ToolInputSection("Workspace") {
            VStack(spacing: 0) {
                ForEach(backend.items) { item in
                    HStack {
                        Image(systemName: item.isDirectory ? "folder.fill" : "doc.text")
                            .foregroundColor(item.isDirectory ? .orange : .blue)
                        VStack(alignment: .leading) {
                            Text(item.url.lastPathComponent)
                            Text(item.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if !item.isDirectory {
                            ShareLink(item: item.url) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        Button {
                            backend.selectedItem = item
                        } label: {
                            Image(systemName: backend.selectedItem?.id == item.id ? "checkmark.circle.fill" : "circle")
                        }
                        Button(role: .destructive) {
                            backend.delete(item)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                    .padding()
                    if item.id != backend.items.last?.id { Divider() }
                }
            }
        }
    }
}
