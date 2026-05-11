import Foundation

struct AIImageFallbackProvider: AISlidesImageProvider {
    func imageURL(for query: String) async -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "presentation"
        return URL(string: "https://dummyimage.com/1280x720/0f172a/ffffff.png&text=\(encoded)")
    }
}
