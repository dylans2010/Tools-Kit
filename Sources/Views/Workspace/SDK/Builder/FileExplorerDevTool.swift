import SwiftUI

struct FileExplorerDevTool: DevTool {
    let id = "file-explorer"
    let name = "File Explorer"
    let category = DevToolCategory.storage
    let icon = "folder.badge.gearshape"
    let description = "Browse and manage application files"

    func render() -> some View {
        FileExplorerView()
    }
}

struct FileExplorerView: View {
    @StateObject private var viewModel = FileExplorerViewModel()
    @State private var searchText = ""
    @State private var showingNewFileSheet = false
    @State private var selectedFile: FileItem?

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search files...", text: $searchText)
                }
            }

            Section {
                if !viewModel.isAtRoot {
                    Button { viewModel.navigateUp() } label: {
                        HStack {
                            Image(systemName: "arrow.up.doc.fill")
                            Text("..")
                            Spacer()
                            Text("Up").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                ForEach(viewModel.files.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }) { file in
                    FileRow(file: file,
                           onNavigate: { viewModel.navigateInto(file) },
                           onDelete: { viewModel.deleteFile(file) },
                           onPreview: { selectedFile = file })
                }
            } header: {
                HStack {
                    Text(viewModel.currentPath.lastPathComponent)
                    Spacer()
                    Text("\(viewModel.files.count) items").font(.caption)
                }
            }
        }
        .navigationTitle("File Explorer")
        .refreshable { viewModel.load() }
        .onAppear { viewModel.load() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewFileSheet = true
                } label: {
                    Image(systemName: "plus.rectangle.on.folder")
                }
            }
        }
        .sheet(isPresented: $showingNewFileSheet) {
            NewFileView(viewModel: viewModel)
        }
        .sheet(item: $selectedFile) { file in
            FilePreviewView(file: file)
        }
    }
}

struct FileRow: View {
    let file: FileItem
    let onNavigate: () -> Void
    let onDelete: () -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                .font(.title3)
                .foregroundStyle(file.isDirectory ? .blue : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.subheadline.bold())
                Text("\(file.size) • \(file.modifiedDate, format: .relative(presentation: .named))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if file.isDirectory {
                Button(action: onNavigate) {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            } else {
                Menu {
                    Button(action: onPreview) {
                        Label("Preview", systemImage: "eye")
                    }
                    Button(action: onDelete, role: .destructive) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct NewFileView: View {
    @ObservedObject var viewModel: FileExplorerViewModel
    @State private var fileName = ""
    @State private var isDirectory = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $fileName)
                Toggle("Directory", isOn: $isDirectory)
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createItem(name: fileName, isDir: isDirectory)
                        dismiss()
                    }
                    .disabled(fileName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct FilePreviewView: View {
    let file: FileItem
    @State private var content = "Loading..."
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
            .onAppear {
                if let data = try? Data(contentsOf: file.path),
                   let string = String(data: data, encoding: .utf8) {
                    content = string
                } else {
                    content = "Unable to preview binary file."
                }
            }
        }
    }
}

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let isDirectory: Bool
    let size: String
    let modifiedDate: Date
}

class FileExplorerViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var currentPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    var isAtRoot: Bool {
        currentPath.pathComponents.count <= 4
    }

    func load() {
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: currentPath, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey], options: .skipsHiddenFiles)

            files = urls.map { url in
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                let size = ByteCountFormatter.string(fromByteCount: Int64(values?.fileSize ?? 0), countStyle: .file)
                return FileItem(
                    name: url.lastPathComponent,
                    path: url,
                    isDirectory: values?.isDirectory ?? false,
                    size: size,
                    modifiedDate: values?.contentModificationDate ?? Date()
                )
            }.sorted {
                if $0.isDirectory != $1.isDirectory {
                    return $0.isDirectory
                }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        } catch {
            files = []
        }
    }

    func navigateInto(_ file: FileItem) {
        currentPath = file.path
        load()
    }

    func navigateUp() {
        currentPath = currentPath.deletingLastPathComponent()
        load()
    }

    func deleteFile(_ file: FileItem) {
        try? FileManager.default.removeItem(at: file.path)
        load()
    }

    func createItem(name: String, isDir: Bool) {
        let url = currentPath.appendingPathComponent(name)
        if isDir {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } else {
            let dummyContent = "Created by ToolsKit DevTool\nTimestamp: \(Date())\n"
            try? dummyContent.write(to: url, atomically: true, encoding: .utf8)
        }
        load()
    }
}

#Preview {
    FileExplorerView()
}
