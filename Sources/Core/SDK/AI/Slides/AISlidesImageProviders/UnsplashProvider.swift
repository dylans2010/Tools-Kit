import Foundation

// MARK: - Unsplash API Response Models

struct UnsplashSearchResponse: Codable {
    let total: Int
    let totalPages: Int
    let results: [UnsplashPhoto]

    enum CodingKeys: String, CodingKey {
        case total
        case totalPages = "total_pages"
        case results
    }
}

struct UnsplashPhoto: Codable, Identifiable, Equatable {
    let id: String
    let width: Int
    let height: Int
    let description: String?
    let altDescription: String?
    let urls: UnsplashPhotoURLs
    let user: UnsplashUser
    let links: UnsplashPhotoLinks

    enum CodingKeys: String, CodingKey {
        case id, width, height, description
        case altDescription = "alt_description"
        case urls, user, links
    }

    static func == (lhs: UnsplashPhoto, rhs: UnsplashPhoto) -> Bool {
        lhs.id == rhs.id
    }
}

struct UnsplashPhotoURLs: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct UnsplashUser: Codable {
    let id: String
    let name: String
    let username: String
}

struct UnsplashPhotoLinks: Codable {
    let html: String
    let download: String
    let downloadLocation: String

    enum CodingKeys: String, CodingKey {
        case html, download
        case downloadLocation = "download_location"
    }
}

// MARK: - Unsplash Provider Error

enum UnsplashProviderError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidAPIKey
    case networkError(String)
    case decodingError(String)
    case noResults
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Unsplash API key is not configured. Add your key in App Settings → API Keys."
        case .invalidAPIKey:
            return "The Unsplash API key is invalid or has been revoked."
        case .networkError(let detail):
            return "Network error: \(detail)"
        case .decodingError(let detail):
            return "Failed to decode Unsplash response: \(detail)"
        case .noResults:
            return "No images found for this search query."
        case .rateLimited:
            return "Unsplash API rate limit exceeded. Try again later."
        case .serverError(let code):
            return "Unsplash server error (HTTP \(code))."
        }
    }
}

// MARK: - UnsplashProvider

final class UnsplashProvider: AISlidesImageProvider {
    static let shared = UnsplashProvider()
    static let providerID = "unsplash"

    private let baseURL = "https://api.unsplash.com"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - AISlidesImageProvider conformance

    func imageURL(for query: String) async -> URL? {
        let result = await search(query: query, page: 1, perPage: 1)
        switch result {
        case .success(let response):
            guard let photo = response.results.first else { return nil }
            return URL(string: photo.urls.regular)
        case .failure:
            return nil
        }
    }

    // MARK: - Full Search API

    func search(
        query: String,
        page: Int = 1,
        perPage: Int = 30,
        orientation: String? = nil
    ) async -> Result<UnsplashSearchResponse, UnsplashProviderError> {
        guard let apiKey = APIKeyManager.shared.getKey(for: UnsplashProvider.providerID),
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.missingAPIKey)
        }

        guard var components = URLComponents(string: "\(baseURL)/search/photos") else {
            return .failure(.networkError("Invalid base URL."))
        }

        var queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        if let orientation {
            queryItems.append(URLQueryItem(name: "orientation", value: orientation))
        }
        components.queryItems = queryItems

        guard let requestURL = components.url else {
            return .failure(.networkError("Failed to construct request URL."))
        }

        var request = URLRequest(url: requestURL)
        request.setValue("Client-ID \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Invalid response type."))
            }

            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                return .failure(.invalidAPIKey)
            case 403:
                return .failure(.rateLimited)
            case 429:
                return .failure(.rateLimited)
            default:
                return .failure(.serverError(httpResponse.statusCode))
            }

            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(UnsplashSearchResponse.self, from: data)

            if searchResponse.results.isEmpty {
                return .failure(.noResults)
            }

            return .success(searchResponse)
        } catch is DecodingError {
            return .failure(.decodingError("Response did not match expected Unsplash schema."))
        } catch let urlError as URLError {
            return .failure(.networkError(urlError.localizedDescription))
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }

    // MARK: - Download Image Data

    func downloadImageData(from photo: UnsplashPhoto, quality: ImageQuality = .regular) async -> Result<Data, UnsplashProviderError> {
        let urlString: String
        switch quality {
        case .thumb: urlString = photo.urls.thumb
        case .small: urlString = photo.urls.small
        case .regular: urlString = photo.urls.regular
        case .full: urlString = photo.urls.full
        }

        guard let url = URL(string: urlString) else {
            return .failure(.networkError("Invalid image URL."))
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .failure(.networkError("Failed to download image."))
            }
            return .success(data)
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }

    enum ImageQuality {
        case thumb, small, regular, full
    }
}
