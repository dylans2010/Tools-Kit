import SwiftUI
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

struct FileFolderContentsView: View {
    @StateObject private var backend: FileFolderBackend
    @State private var newFolderName = ""
    @State private var newFileName = ""
    @State private var selectedType: ManagedFileType = .text
    @State private var showingImporter = false
    @State private var showingCreateFile = false
    @State private var showingCreateFolder = false
    private let folderName: String

    init(folderURL: URL) {
        _backend = StateObject(wrappedValue: FileFolderBackend(folderURL: folderURL))
        folderName = folderURL.lastPathComponent
    }

    var body: some View {
        List {
            // Items inside the folder
            if backend.items.isEmpty {
                ContentUnavailableView(
                    "Empty Folder",
                    systemImage: "folder",
                    description: Text("Add files or sub-folders using the buttons below.")
                )
            } else {
                ForEach(backend.items) { item in
                    if item.isDirectory {
                        NavigationLink(destination: FileFolderContentsView(folderURL: item.url)) {
                            FileItemRowView(item: item)
                        }
                    } else {
                        FileItemRowView(item: item)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    backend.delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { backend.delete(backend.items[$0]) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(folderName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingCreateFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                Button {
                    showingCreateFile = true
                } label: {
                    Image(systemName: "doc.badge.plus")
                }
                Button {
                    showingImporter = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
        .sheet(isPresented: $showingCreateFolder) {
            CreateFolderSheet(onCreate: { name in
                backend.createFolder(name: name)
                showingCreateFolder = false
            })
        }
        .sheet(isPresented: $showingCreateFile) {
            CreateFileSheet(onCreate: { name, type in
                backend.createFile(name: name, type: type)
                showingCreateFile = false
            })
        }
        .sheet(isPresented: $showingImporter) {
            FileImporterRepresentableView(
                allowedContentTypes: [UTType.item],
                allowsMultipleSelection: true
            ) { urls in
                backend.importFiles(urls: urls)
                showingImporter = false
            }
        }
        .refreshable { backend.reload() }
    }
}

// MARK: - File Row

private struct FileItemRowView: View {
    let item: ManagedFileItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isDirectory ? "folder.fill" : iconName)
                .font(.title3)
                .foregroundColor(item.isDirectory ? .orange : .blue)
                .frame(width: 32)

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

            if !item.isDirectory {
                ShareLink(item: item.url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
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

// MARK: - Create Folder Sheet

private struct CreateFolderSheet: View {
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                } header: {
                    Text("Folder Name")
                }
                Button("Create Folder") {
                    onCreate(name)
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("New Folder")
            .toolbar { Button("Cancel") { dismiss() } }
        }
    }
}

// MARK: - Create File Sheet

private struct CreateFileSheet: View {
    let onCreate: (String, ManagedFileType) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: ManagedFileType = .text

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(ManagedFileType.allCases) { t in
                            Text(".\(t.rawValue)").tag(t)
                        }
                    }
                } header: {
                    Text("File Details")
                }
                Button("Create File") {
                    onCreate(name, type)
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("New File")
            .toolbar { Button("Cancel") { dismiss() } }
        }
    }
}
