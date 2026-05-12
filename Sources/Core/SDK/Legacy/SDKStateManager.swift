import Foundation

/// Persistent state management for SDK projects.
public final class SDKStateManager: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKStateManager()

    @Published public var savedProjects: [SDKProjectLegacy] = []

    private let savePath: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        savePath = docs.appendingPathComponent("sdk_projects.json")
        loadProjects()
    }

    public func saveProject(_ project: SDKProjectLegacy) {
        if let index = savedProjects.firstIndex(where: { $0.id == project.id }) {
            savedProjects[index] = project
        } else {
            savedProjects.append(project)
        }
        persist()
    }

    private func loadProjects() {
        guard let data = try? Data(contentsOf: savePath) else { return }
        if let decoded = try? JSONDecoder().decode([SDKProjectLegacy].self, from: data) {
            savedProjects = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(savedProjects) {
            try? data.write(to: savePath)
        }
    }
}
