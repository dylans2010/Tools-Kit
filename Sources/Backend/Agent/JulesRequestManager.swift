import Foundation

protocol JulesPayloadValidating {
    func validationErrors() -> [JulesRequestManager.FieldValidationError]
}

final class JulesRequestManager {
    static let shared = JulesRequestManager()

    struct FieldValidationError: Error, Sendable {
        let field: String
        let reason: String
    }

    struct APIErrorEnvelope: Decodable, Sendable {
        struct APIError: Decodable, Sendable {
            let code: Int?
            let status: String?
            let message: String?
            let details: [AnyCodable]?
        }
        let error: APIError?
    }

    enum JulesRequestError: Error, LocalizedError, Sendable {
        case missingOrInvalidAPIKey
        case invalidRepositoryURL(String)
        case invalidPayload([FieldValidationError])
        case invalidResponse
        case apiError(statusCode: Int, message: String, fieldFailures: [FieldValidationError])

        var errorDescription: String? {
            switch self {
            case .missingOrInvalidAPIKey:
                return "Missing or invalid Jules API key"
            case .invalidRepositoryURL(let reason):
                return "Invalid repository URL: \(reason)"
            case .invalidPayload(let errors):
                let message = errors.map { "\($0.field): \($0.reason)" }.joined(separator: "; ")
                return "Invalid request payload: \(message)"
            case .invalidResponse:
                return "Received an invalid response from the Jules API."
            case .apiError(let statusCode, let message, _):
                return "HTTP \(statusCode): \(message)"
            }
        }
    }

    private let baseURL = URL(string: "https://jules.googleapis.com/v1alpha")!
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let debugSafetyMode: Bool

    init(session: URLSession = .shared, debugSafetyMode: Bool = true) {
        self.session = session
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.sortedKeys]
        self.debugSafetyMode = debugSafetyMode
    }

    func fetchKeyFromKeychain() throws -> String {
        let raw = APIKeyManager.shared.getKey(for: "jules") ?? AgentKeychainManager.shared.getKey() ?? ""
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            log("Missing or invalid Jules API key")
            throw JulesRequestError.missingOrInvalidAPIKey
        }
        return key
    }

    func validateRepositoryURL(_ rawValue: String) throws -> URL {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw JulesRequestError.invalidRepositoryURL("Repository URL is empty")
        }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "https",
              let host = url.host?.lowercased(),
              host == "github.com" else {
            throw JulesRequestError.invalidRepositoryURL("Repository URL must use https://github.com/<owner>/<repo>")
        }
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2,
              !pathComponents[0].isEmpty,
              !pathComponents[1].isEmpty else {
            throw JulesRequestError.invalidRepositoryURL("Repository URL must include owner and repository")
        }
        return url
    }

    func send<Response: Decodable>(
        path: String,
        method: String = "GET",
        apiKeyOverride: String? = nil
    ) async throws -> Response {
        let data = try await perform(path: path, method: method, body: Optional<JulesNoBody>.none, apiKeyOverride: apiKeyOverride)
        return try decoder.decode(Response.self, from: data)
    }

    func send<Response: Decodable, Body: Encodable & JulesPayloadValidating>(
        path: String,
        method: String = "GET",
        body: Body,
        apiKeyOverride: String? = nil
    ) async throws -> Response {
        let data = try await perform(path: path, method: method, body: body, apiKeyOverride: apiKeyOverride)
        return try decoder.decode(Response.self, from: data)
    }

    func sendVoid(
        path: String,
        method: String = "GET",
        apiKeyOverride: String? = nil
    ) async throws {
        _ = try await perform(path: path, method: method, body: Optional<JulesNoBody>.none, apiKeyOverride: apiKeyOverride)
    }

    func sendVoid<Body: Encodable & JulesPayloadValidating>(
        path: String,
        method: String = "GET",
        body: Body,
        apiKeyOverride: String? = nil
    ) async throws {
        _ = try await perform(path: path, method: method, body: body, apiKeyOverride: apiKeyOverride)
    }

    private func perform<Body: Encodable & JulesPayloadValidating>(
        path: String,
        method: String,
        body: Body?,
        apiKeyOverride: String?
    ) async throws -> Data {
        let apiKey = try (apiKeyOverride?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                          ? apiKeyOverride!.trimmingCharacters(in: .whitespacesAndNewlines)
                          : fetchKeyFromKeychain())

        if let body {
            let errors = body.validationErrors()
            if !errors.isEmpty {
                logInvalidPayload(errors)
                if debugSafetyMode {
                    assertionFailure("Debug safety mode blocked invalid Jules payload: \(errors)")
                }
                throw JulesRequestError.invalidPayload(errors)
            }
        }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        logRequest(request)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw JulesRequestError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let parsed = parseAPIError(data)
            let fieldFailures = extractFieldFailures(from: parsed.details)
            if http.statusCode == 400, !fieldFailures.isEmpty {
                for failure in fieldFailures {
                    log("Invalid field: \(failure.field) — reason: \(failure.reason)")
                }
            }
            throw JulesRequestError.apiError(statusCode: http.statusCode, message: parsed.message, fieldFailures: fieldFailures)
        }

        return data
    }

    private func parseAPIError(_ data: Data) -> (message: String, details: [AnyCodable]?) {
        let raw = String(data: data, encoding: .utf8) ?? "<non-utf8-body>"
        log("Jules API error body: \(raw)")
        if let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data),
           let error = envelope.error {
            let message = "[\(error.status ?? "UNKNOWN") #\(error.code.map(String.init) ?? "?")] \(error.message ?? "No message")"
            if let details = error.details {
                log("Jules API error details: \(details.map { String(describing: $0.value) }.joined(separator: " | "))")
            }
            return (message, error.details)
        }
        return (raw, nil)
    }

    private func extractFieldFailures(from details: [AnyCodable]?) -> [FieldValidationError] {
        guard let details else { return [] }
        var failures: [FieldValidationError] = []

        for detail in details {
            guard let dict = detail.value as? [String: Any] else { continue }
            let field = (dict["field"] as? String)
                ?? (dict["fieldViolations"] as? [[String: Any]])?.first?["field"] as? String
                ?? (dict["violations"] as? [[String: Any]])?.first?["field"] as? String
                ?? "unknown"
            let reason = (dict["description"] as? String)
                ?? (dict["reason"] as? String)
                ?? (dict["message"] as? String)
                ?? (dict["fieldViolations"] as? [[String: Any]])?.first?["description"] as? String
                ?? "No reason provided"
            failures.append(FieldValidationError(field: field, reason: reason))
        }

        return failures
    }

    private func logRequest(_ request: URLRequest) {
        let headers = Dictionary(uniqueKeysWithValues: (request.allHTTPHeaderFields ?? [:]).map { key, value in
            let shouldMask = key.lowercased().contains("key") || key.lowercased().contains("authorization")
            return (key, shouldMask ? "***MASKED***" : value)
        })
        log("Jules request URL: \(request.url?.absoluteString ?? "")")
        log("Jules request headers: \(headers)")
        if let body = request.httpBody, let raw = String(data: body, encoding: .utf8) {
            log("Jules request JSON body: \(raw)")
        } else {
            log("Jules request JSON body: <none>")
        }
    }

    private func logInvalidPayload(_ errors: [FieldValidationError]) {
        for error in errors {
            log("Invalid field: \(error.field) — reason: \(error.reason)")
        }
    }

    private func log(_ message: String) {
        print("[JulesRequestManager] \(message)")
    }
}

struct JulesNoBody: Encodable, JulesPayloadValidating, Sendable {
    func validationErrors() -> [JulesRequestManager.FieldValidationError] { [] }
}
