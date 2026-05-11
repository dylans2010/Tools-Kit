import Foundation

struct PexelsProvider: AISlidesImageProvider {
    private let fallbackGallery: [URL] = [
        URL(string: "https://images.pexels.com/photos/3184292/pexels-photo-3184292.jpeg")!,
        URL(string: "https://images.pexels.com/photos/3861969/pexels-photo-3861969.jpeg")!,
        URL(string: "https://images.pexels.com/photos/3183150/pexels-photo-3183150.jpeg")!,
        URL(string: "https://images.pexels.com/photos/3861972/pexels-photo-3861972.jpeg")!
    ]

    func imageURL(for query: String) async -> URL? {
        let index = abs(query.hashValue) % fallbackGallery.count
        return fallbackGallery[index]
    }
}
