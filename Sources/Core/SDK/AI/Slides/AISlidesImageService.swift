import Foundation

protocol AISlidesImageProvider {
    func imageURL(for query: String) async -> URL?
}

struct AISlidesImageService {
    private let cache = AISlidesCache.shared
    private let providers: [AISlidesImageProvider] = [
        UnsplashProvider.shared,
        PexelsProvider(),
        AIImageFallbackProvider()
    ]

    func resolveImage(for query: String) async -> URL? {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return nil }

        print("[ImageService] Fetching image for query: \(normalizedQuery)")

        let key = AISlidesCache.hash(normalizedQuery)
        if let cached = await cache.cachedImageURL(for: key) {
            print("[ImageService] Cache hit for: \(normalizedQuery)")
            return cached
        }

        for provider in providers {
            print("[ImageService] Trying provider: \(type(of: provider))")
            if let candidate = await provider.imageURL(for: normalizedQuery) {
                print("[ImageService] Success from \(type(of: provider)): \(candidate.absoluteString.prefix(80))")
                await cache.storeImageURL(candidate, for: key)
                await cache.storeImageURL(candidate, for: "fallback_\(key)")
                return candidate
            }
            print("[ImageService] Provider \(type(of: provider)) returned nil, trying next")
        }

        if let cachedFallback = await cache.cachedImageURL(for: "fallback_\(key)") {
            print("[ImageService] Using cached fallback for: \(normalizedQuery)")
            return cachedFallback
        }

        print("[ImageService] All providers failed for: \(normalizedQuery)")
        return nil
    }
}
