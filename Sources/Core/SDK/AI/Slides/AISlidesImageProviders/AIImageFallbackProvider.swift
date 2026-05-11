import Foundation

struct AIImageFallbackProvider: AISlidesImageProvider {
    func imageURL(for query: String) async -> URL? {
        nil
    }
}
