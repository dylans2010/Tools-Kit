import SwiftUI

struct SecureFoldersView: View {
    @StateObject private var folderManager = SecureFolderManager.shared
    @State private var showingAddFolder = false
    @State private var newFolderName = ""

    var body: some View {
        List {
            if folderManager.folders.isEmpty {
                ContentUnavailableView(
                    "No Secure Folders",
                    systemImage: "folder.badge.plus",
                    description: Text("Create a folder to group your sensitive items.")
                )
            } else {
                ForEach(folderManager.folders) { folder in
                    NavigationLink(destination: SecureFolderDetailView(folder: folder)) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(folder.name)
                                    .font(.headline)
                                Text("\(folder.items.count) items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            try? folderManager.deleteFolder(id: folder.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Secure Folders")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddFolder = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Folder", isPresented: $showingAddFolder) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) { newFolderName = "" }
            Button("Create") {
                if !newFolderName.isEmpty {
                    try? folderManager.createFolder(name: newFolderName)
                    newFolderName = ""
                }
            }
        }
    }
}

struct SecureFolderDetailView: View {
    let folder: SecureFolder
    @StateObject private var folderManager = SecureFolderManager.shared
    @State private var showingPicker = false

    var body: some View {
        List {
            if folder.items.isEmpty {
                Text("No items in this folder")
                    .foregroundColor(.secondary)
            } else {
                ForEach(folder.items, id: \.self.hashValue) { item in
                    FolderItemRow(item: item)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let item = folder.items[index]
                        try? folderManager.removeItem(from: folder.id, item: item)
                    }
                }
            }
        }
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingPicker = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            SecureFolderItemPicker { item in
                try? folderManager.addItem(to: folder.id, item: item)
            }
        }
    }
}

struct FolderItemRow: View {
    let item: SecureFolderItem

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var icon: String {
        switch item {
        case .password: return "key.fill"
        case .file: return "doc.fill"
        case .photo: return "photo.fill"
        case .note: return "note.text"
        case .app: return "app.badge.key"
        }
    }

    private var title: String {
        switch item {
        case .password(let id):
            if let vaultItem = VaultManager.shared.items.first(where: { $0.id.uuidString == id }) {
                return vaultItem.title
            }
            return "Password (\(id.prefix(8)))"
        case .file(let id): return "File (\(id.prefix(8)))"
        case .photo(let id): return "Photo (\(id.prefix(8)))"
        case .note(let id): return "Note (\(id.prefix(8)))"
        case .app(let id):
            if let profile = AppLockManager.shared.profiles.first(where: { $0.id == id }) {
                return profile.name
            }
            return "App Lock (\(id.prefix(8)))"
        }
    }

    private var subtitle: String {
        switch item {
        case .password: return "Security Module"
        case .file: return "Files Module"
        case .photo: return "Media Module"
        case .note: return "Notes Module"
        case .app: return "App Lock Group"
        }
    }
}
