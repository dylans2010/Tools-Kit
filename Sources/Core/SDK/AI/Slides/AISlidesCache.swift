import Foundation

actor AISlidesCache {
    static let shared = AISlidesCache()

    private var textCache: [String: String] = [:]
    private var imageCache: [String: URL] = [:]

    private init() {}

    func cachedJSON(for key: String) -> String? {
        textCache[key]
    }

    func storeJSON(_ value: String, for key: String) {
        textCache[key] = value
    }

    func cachedImageURL(for key: String) -> URL? {
        imageCache[key]
    }

    func storeImageURL(_ value: URL, for key: String) {
        imageCache[key] = value
    }

    static func hash(_ value: String) -> String {
        String(value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).hashValue)
    }
}
