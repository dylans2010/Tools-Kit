import Foundation
import Combine

@MainActor
class SecureFolderManager: ObservableObject {
    static let shared = SecureFolderManager()

    @Published private(set) var folders: [SecureFolder] = []

    private let dataStore = UnifiedDataStore.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.folders = dataStore.loadSecureFolders()

        // Sync with data store changes
        dataStore.$secureFolders
            .assign(to: \.folders, on: self)
            .store(in: &cancellables)
    }

    func createFolder(name: String) throws {
        var currentFolders = folders
        let newFolder = SecureFolder(name: name)
        currentFolders.append(newFolder)
        try dataStore.saveSecureFolders(currentFolders)
    }

    func renameFolder(id: String, newName: String) throws {
        var currentFolders = folders
        if let index = currentFolders.firstIndex(where: { $0.id == id }) {
            currentFolders[index].name = newName
            try dataStore.saveSecureFolders(currentFolders)
        }
    }

    func deleteFolder(id: String) throws {
        var currentFolders = folders
        currentFolders.removeAll { $0.id == id }
        try dataStore.saveSecureFolders(currentFolders)
    }

    func addItem(to folderId: String, item: SecureFolderItem) throws {
        var currentFolders = folders
        if let index = currentFolders.firstIndex(where: { $0.id == folderId }) {
            currentFolders[index].items.append(item)
            try dataStore.saveSecureFolders(currentFolders)
        }
    }

    func removeItem(from folderId: String, item: SecureFolderItem) throws {
        var currentFolders = folders
        if let index = currentFolders.firstIndex(where: { $0.id == folderId }) {
            currentFolders[index].items.removeAll { $0 == item }
            try dataStore.saveSecureFolders(currentFolders)
        }
    }

    func moveItem(item: SecureFolderItem, from sourceId: String, to destinationId: String) throws {
        var currentFolders = folders
        if let sourceIndex = currentFolders.firstIndex(where: { $0.id == sourceId }),
           let destIndex = currentFolders.firstIndex(where: { $0.id == destinationId }) {

            currentFolders[sourceIndex].items.removeAll { $0 == item }
            currentFolders[destIndex].items.append(item)
            try dataStore.saveSecureFolders(currentFolders)
        }
    }
}
