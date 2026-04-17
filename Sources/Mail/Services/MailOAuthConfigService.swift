import Foundation

struct MailOAuthConfig {
    let clientID: String
    let redirectURI: String
}

enum MailOAuthConfigError: LocalizedError {
    case missingClientID
    case missingRedirectURI

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Missing GOOGLE_OAUTH_CLIENT_ID (Appwrite global vars or Config.plist)"
        case .missingRedirectURI:
            return "Missing GOOGLE_OAUTH_REDIRECT_URI (Appwrite global vars or Config.plist)"
        }
    }
}

actor MailOAuthConfigService {
    static let shared = MailOAuthConfigService()

    private var cachedConfig: MailOAuthConfig?

    func resolvedConfig() async throws -> MailOAuthConfig {
        if let cachedConfig {
            return cachedConfig
        }

        let remote = await fetchRemoteVariables()

        let clientID = firstNonEmpty([
            remote["GOOGLE_OAUTH_CLIENT_ID"],
            remote["GOOGLE_WEB_CLIENT_ID"],
            Self.localConfigValue(forKey: "GOOGLE_OAUTH_CLIENT_ID")
        ])

        let redirectURI = firstNonEmpty([
            remote["GOOGLE_OAUTH_REDIRECT_URI"],
            remote["GOOGLE_WEB_REDIRECT_URI"],
            Self.localConfigValue(forKey: "GOOGLE_OAUTH_REDIRECT_URI")
        ])

        guard let clientID else {
            throw MailOAuthConfigError.missingClientID
        }
        guard let redirectURI else {
            throw MailOAuthConfigError.missingRedirectURI
        }

        let resolved = MailOAuthConfig(clientID: clientID, redirectURI: redirectURI)
        cachedConfig = resolved
        return resolved
    }

    func clearCache() {
        cachedConfig = nil
    }

    private func fetchRemoteVariables() async -> [String: String] {
        guard
            let rawURL = Self.localConfigValue(forKey: "APPWRITE_MAIL_CONFIG_URL"),
            let url = URL(string: rawURL)
        else {
            return [:]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let bearer = Self.localConfigValue(forKey: "APPWRITE_MAIL_CONFIG_BEARER") {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return [:]
            }

            if let direct = try? JSONDecoder().decode([String: String].self, from: data) {
                return direct
            }

            if let wrapped = try? JSONDecoder().decode(AppwriteVariableEnvelope.self, from: data) {
                var parsed: [String: String] = [:]
                for item in wrapped.variables {
                    parsed[item.key] = item.value
                }
                for (key, value) in wrapped.data {
                    parsed[key] = value
                }
                return parsed
            }

            return [:]
        } catch {
            return [:]
        }
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        for value in values {
            guard let value else { continue }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }

    private static func localConfigValue(forKey key: String) -> String? {
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let value = plist[key] as? String
        else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct AppwriteVariableEnvelope: Decodable {
    let variables: [VariableItem]
    let data: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.variables = (try? container.decode([VariableItem].self, forKey: .variables)) ?? []
        self.data = (try? container.decode([String: String].self, forKey: .data)) ?? [:]
    }

    private enum CodingKeys: String, CodingKey {
        case variables
        case data
    }
}

private struct VariableItem: Decodable {
    let key: String
    let value: String
}