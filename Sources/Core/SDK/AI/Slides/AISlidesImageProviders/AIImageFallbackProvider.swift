import Foundation

struct AIImageFallbackProvider: AISlidesImageProvider {
    func imageURL(for query: String) async -> URL? {
        print("[AIImageFallback] Generating fallback image for: \(query)")
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "presentation"

        let candidates = [
            "https://source.unsplash.com/1280x720/?\(encoded)",
            "https://picsum.photos/1280/720",
            "https://dummyimage.com/1280x720/0f172a/ffffff.png&text=\(encoded)"
        ]

        for candidate in candidates {
            if let url = URL(string: candidate) {
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 5

                do {
                    let (_, response) = try await URLSession.shared.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse,
                       (200...399).contains(httpResponse.statusCode) {
                        print("[AIImageFallback] Success: \(candidate.prefix(60))")
                        return url
                    }
                } catch {
                    continue
                }
            }
        }

        let fallbackURL = URL(string: "https://dummyimage.com/1280x720/0f172a/ffffff.png&text=\(encoded)")
        print("[AIImageFallback] Using final fallback URL")
        return fallbackURL
    }
}
