import Foundation

struct AIAuthorization {
    enum Mode {
        case appModel
        case ownKey
    }

    let apiKey: String
    let mode: Mode
}

enum AIFeatureCheckError: LocalizedError {
    case dailyLimitReached(limit: Int)
    case missingOwnAPIKey
    case missingProductionAPIKey

    var errorDescription: String? {
        switch self {
        case .dailyLimitReached(let limit):
            return "Daily AI request limit reached (\(limit))."
        case .missingOwnAPIKey:
            return "No API key saved for your selected provider."
        case .missingProductionAPIKey:
            return "App Model key is not configured (PRODUCTION_API_KEY)."
        }
    }
}

@MainActor
final class AIFeatureCheck: ObservableObject {
    static let shared = AIFeatureCheck()

    @Published private(set) var requestsToday: Int = 0

    let dailyAppModelLimit = 10

    private let defaults = UserDefaults.standard
    private let keyManager = APIKeyManager.shared
    private let settingsManager = AIChatSettingsManager.shared

    private var cachedProductionAPIKey: String?

    private init() {
        requestsToday = defaults.integer(forKey: requestsKey(for: Date()))
    }

    func refresh() {
        requestsToday = defaults.integer(forKey: requestsKey(for: Date()))
    }

    func usageMessage() -> String {
        let count = requestsToday
        if settingsManager.settings.aiModelSource == .ownKey {
            return "\(count) Out Of Unlimited"
        }
        return "\(count) out of \(dailyAppModelLimit) requests"
    }

    func authorizeRequest(providerID: String) async throws -> AIAuthorization {
        refresh()

        switch settingsManager.settings.aiModelSource {
        case .ownKey:
            guard let key = keyManager.getKey(for: providerID), !key.isEmpty else {
                throw AIFeatureCheckError.missingOwnAPIKey
            }
            incrementRequestCount()
            return AIAuthorization(apiKey: key, mode: .ownKey)

        case .appModel:
            if requestsToday >= dailyAppModelLimit {
                throw AIFeatureCheckError.dailyLimitReached(limit: dailyAppModelLimit)
            }

            let key = try await productionAPIKey()
            incrementRequestCount()
            return AIAuthorization(apiKey: key, mode: .appModel)
        }
    }

    func usingOwnKey() -> Bool {
        settingsManager.settings.aiModelSource == .ownKey
    }

    private func incrementRequestCount() {
        let key = requestsKey(for: Date())
        let updated = defaults.integer(forKey: key) + 1
        defaults.set(updated, forKey: key)
        requestsToday = updated
    }

    private func requestsKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return "ai_requests_\(formatter.string(from: date))"
    }

    private func productionAPIKey() async throws -> String {
        if let cachedProductionAPIKey, !cachedProductionAPIKey.isEmpty {
            return cachedProductionAPIKey
        }

        let remote = await fetchRemoteVariables()
        if let remoteKey = remote["PRODUCTION_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines), !remoteKey.isEmpty {
            cachedProductionAPIKey = remoteKey
            return remoteKey
        }

        if let local = Self.localConfigValue(forKey: "PRODUCTION_API_KEY") {
            cachedProductionAPIKey = local
            return local
        }

        throw AIFeatureCheckError.missingProductionAPIKey
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
            return Self.decodeRemoteVariables(from: data)
        } catch {
            return [:]
        }
    }

    private static func localConfigValue(forKey key: String) -> String? {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }

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

    private static func decodeRemoteVariables(from data: Data) -> [String: String] {
        if let direct = try? JSONDecoder().decode([String: String].self, from: data) {
            return direct
                .mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.value.isEmpty }
        }

        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return [:]
        }

        var values: [String: String] = [:]
        collectRemoteVariables(from: object, into: &values, parentKey: nil)
        return values
            .mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.value.isEmpty }
    }

    private static func collectRemoteVariables(from object: Any, into output: inout [String: String], parentKey: String?) {
        switch object {
        case let dictionary as [String: Any]:
            if let key = dictionary["key"] as? String, let value = dictionary["value"] as? String {
                output[key] = value
            }
            if let parentKey, let value = dictionary["value"] as? String, looksLikeConfigKey(parentKey) {
                output[parentKey] = value
            }

            for (key, value) in dictionary {
                if let stringValue = value as? String, looksLikeConfigKey(key) {
                    output[key] = stringValue
                }
                collectRemoteVariables(from: value, into: &output, parentKey: key)
            }
        case let array as [Any]:
            for item in array {
                collectRemoteVariables(from: item, into: &output, parentKey: parentKey)
            }
        default:
            break
        }
    }

    private static func looksLikeConfigKey(_ key: String) -> Bool {
        guard key.range(of: #"^[A-Z][A-Z0-9_]*$"#, options: .regularExpression) != nil else { return false }
        let allowedPrefixes = ["APPWRITE_", "GOOGLE_", "GMAIL_", "PRODUCTION_", "DAILY_", "MAIL_", "OUTLOOK_", "YAHOO_"]
        return allowedPrefixes.contains { key.hasPrefix($0) }
    }
}
