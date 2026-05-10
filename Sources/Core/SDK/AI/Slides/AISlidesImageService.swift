import Foundation

struct AISlidesImageService {
    private let cache = AISlidesCache.shared

    func resolveImage(for query: String) async -> URL? {
        let key = AISlidesCache.hash(query)
        if let cached = await cache.cachedImageURL(for: key) {
            return cached
        }

        if let searched = await searchAPIImage(query: query) {
            await cache.storeImageURL(searched, for: key)
            return searched
        }

        if let fallback = await generateAIImage(query: query) {
            await cache.storeImageURL(fallback, for: key)
            return fallback
        }

        return nil
    }

    private func searchAPIImage(query: String) async -> URL? {
        var components = URLComponents(string: "https://source.unsplash.com/featured")
        components?.queryItems = [URLQueryItem(name: "query", value: query)]
        guard let url = components?.url else { return nil }
        return url
    }

    private func generateAIImage(query: String) async -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "presentation"
        return URL(string: "https://dummyimage.com/1280x720/0f172a/ffffff.png&text=\(encoded)")
    }
}
