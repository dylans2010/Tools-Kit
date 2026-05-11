import Foundation

protocol AISlidesImageProvider {
    func imageURL(for query: String) async -> URL?
}

struct AISlidesImageService {
    private let cache = AISlidesCache.shared
    private let providers: [AISlidesImageProvider] = [
        UnsplashProvider(),
        PexelsProvider(),
        AIImageFallbackProvider()
    ]

    func resolveImage(for query: String) async -> URL? {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return nil }

        let key = AISlidesCache.hash(normalizedQuery)
        if let cached = await cache.cachedImageURL(for: key) {
            return cached
        }

        for provider in providers {
            if let candidate = await provider.imageURL(for: normalizedQuery) {
                await cache.storeImageURL(candidate, for: key)
                await cache.storeImageURL(candidate, for: "fallback_\(key)")
                return candidate
            }
        }

        if let cachedFallback = await cache.cachedImageURL(for: "fallback_\(key)") {
            return cachedFallback
        }

        return nil
    }
}
