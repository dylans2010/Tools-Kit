import Foundation

struct UnsplashProvider: AISlidesImageProvider {
    func imageURL(for query: String) async -> URL? {
        var components = URLComponents(string: "https://source.unsplash.com/featured")
        components?.queryItems = [URLQueryItem(name: "query", value: query)]
        return components?.url
    }
}
