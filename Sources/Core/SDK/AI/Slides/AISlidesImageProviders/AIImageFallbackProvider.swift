import Foundation

struct AIImageFallbackProvider: AISlidesImageProvider, Sendable {
    func imageURL(for query: String) async -> URL? {
        nil
    }
}
