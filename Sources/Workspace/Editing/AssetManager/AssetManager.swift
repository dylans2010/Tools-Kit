import Foundation

/// Represents a media asset in the central library.
struct MediaAsset: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: AssetType
    var tags: [String]
    let size: Int64
    let duration: TimeInterval?

    enum AssetType: String, Codable { case image, video, audio, overlay }
}

/// Manages a central media library for editing projects.
final class AssetManager: ObservableObject {
    static let shared = AssetManager()

    @Published var library: [MediaAsset] = []

    private init() {}

    func addAsset(name: String, type: MediaAsset.AssetType, size: Int64, duration: TimeInterval?) {
        let asset = MediaAsset(id: UUID(), name: name, type: type, tags: [], size: size, duration: duration)
        library.append(asset)
    }

    func searchAssets(query: String) -> [MediaAsset] {
        return library.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) }) }
    }
}
