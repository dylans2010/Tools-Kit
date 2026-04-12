import SwiftUI

struct FileManagementWorkspaceSectionView: View {
    @ObservedObject var backend: FileManagementBackend

    var body: some View {
        ToolInputSection("Workspace") {
            if backend.items.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "folder")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No files yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(backend.items) { item in
                        if item.isDirectory {
                            NavigationLink(destination: FileFolderContentsView(folderURL: item.url)) {
                                workspaceRow(item: item)
                            }
                            .buttonStyle(.plain)
                        } else {
                            workspaceRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture { backend.selectedItem = item }
                        }
                        if item.id != backend.items.last?.id { Divider().padding(.leading, 52) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func workspaceRow(item: ManagedFileItem) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.isDirectory ? "folder.fill" : fileIcon(for: item))
                .font(.title3)
                .foregroundColor(item.isDirectory ? .orange : .blue)
                .frame(width: 36)

            // Name + date
            VStack(alignment: .leading, spacing: 2) {
                Text(item.url.lastPathComponent)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if !item.isDirectory {
                        Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text(item.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                if !item.isDirectory {
                    ShareLink(item: item.url) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }

                if !item.isDirectory {
                    Button {
                        backend.selectedItem = item
                    } label: {
                        Image(systemName: backend.selectedItem?.id == item.id ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(backend.selectedItem?.id == item.id ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button(role: .destructive) {
                    backend.delete(item)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func fileIcon(for item: ManagedFileItem) -> String {
        let ext = item.url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext"
        case "png", "jpg", "jpeg", "heic", "gif", "webp": return "photo"
        case "mp4", "mov", "m4v": return "film"
        case "mp3", "m4a", "wav", "aac": return "music.note"
        case "zip", "gz", "tar": return "archivebox"
        case "swift": return "swift"
        case "json": return "doc.badge.gearshape"
        case "html", "htm": return "globe"
        default: return "doc.text"
        }
    }
}

