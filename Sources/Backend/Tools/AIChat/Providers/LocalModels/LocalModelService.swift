import Foundation
import SwiftUI

struct LocalModelValidationResult {
    let success: Bool
    let provider: LocalProviderType
    let models: [AIModel]
    let error: String?
    let diagnostics: [String]
}

final class LocalModelService: ObservableObject {
    static let shared = LocalModelService()

    private init() {}

    /// Validates a single endpoint and performs the full onboarding pipeline.
    func validateAndDiscover(endpoint: String, apiKey: String = "", customHeaders: [String: String] = [:]) async -> LocalModelValidationResult {
        var diagnostics: [String] = []

        // STAGE 1 - ENDPOINT VALIDATION
        diagnostics.append("Stage 1: Validating endpoint format...")
        guard let url = URL(string: endpoint),
              (url.scheme == "http" || url.scheme == "https"),
              let host = url.host, !host.isEmpty else {
            return .failure("Invalid URL format. Must include http/https and a valid host.", diagnostics: diagnostics)
        }

        if !url.path.contains("/chat/completions") {
            return .failure("Endpoint must end with /chat/completions", diagnostics: diagnostics)
        }
        diagnostics.append("Endpoint validated: \(endpoint)")

        // STAGE 2 - ROOT URL DERIVATION
        diagnostics.append("Stage 2: Deriving root URL...")
        let rootURLString = "\(url.scheme ?? "http")://\(host)\(url.port != nil ? ":\(url.port!)" : "")"
        guard let rootURL = URL(string: rootURLString) else {
            return .failure("Could not derive root URL from \(endpoint)", diagnostics: diagnostics)
        }
        diagnostics.append("Root URL derived: \(rootURLString)")

        // STAGE 3 - ROOT SERVER VALIDATION
        diagnostics.append("Stage 3: Validating root server connectivity...")
        do {
            var rootRequest = URLRequest(url: rootURL)
            rootRequest.timeoutInterval = 5
            let (_, response) = try await URLSession.shared.data(for: rootRequest)
            if let httpResponse = response as? HTTPURLResponse {
                diagnostics.append("Root server responded with status: \(httpResponse.statusCode)")
            }
        } catch {
            diagnostics.append("Root server validation warning: \(error.localizedDescription)")
            // We continue anyway as some servers might not have a root GET handler but chat works
        }

        // STAGE 4 - CHAT ENDPOINT VALIDATION
        diagnostics.append("Stage 4: Validating chat endpoint...")
        do {
            var chatRequest = URLRequest(url: url)
            chatRequest.httpMethod = "POST"
            chatRequest.timeoutInterval = 10
            chatRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if !apiKey.isEmpty {
                chatRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            customHeaders.forEach { chatRequest.setValue($1, forHTTPHeaderField: $0) }

            // Lightweight compatibility request (invalid model to see if it responds with JSON)
            let body: [String: Any] = [
                "model": "probe-connection-test",
                "messages": [["role": "user", "content": "ping"]],
                "max_tokens": 1
            ]
            chatRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: chatRequest)
            if let httpResponse = response as? HTTPURLResponse {
                diagnostics.append("Chat endpoint responded with status: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    return .failure("Authentication failed (401). Check your API Key.", diagnostics: diagnostics)
                }
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                diagnostics.append("Chat endpoint returned valid JSON.")
            }
        } catch {
            return .failure("Chat endpoint unreachable: \(error.localizedDescription)", diagnostics: diagnostics)
        }

        // STAGE 5 - LOCAL PROVIDER DETECTION
        diagnostics.append("Stage 5: Detecting provider...")
        var detectedProvider: LocalProviderType = .unknown

        // Try Ollama detection via root or specific paths
        if await checkOllama(rootURL: rootURLString) {
            detectedProvider = .ollama
        } else if await checkLMStudio(rootURL: rootURLString) {
            detectedProvider = .lmStudio
        } else {
            detectedProvider = .openAICompatible
        }
        diagnostics.append("Detected provider: \(detectedProvider.rawValue)")

        // STAGE 6 - MODEL DISCOVERY
        diagnostics.append("Stage 6: Discovering models...")
        var discoveredModels: [AIModel] = []

        if detectedProvider == .ollama {
            discoveredModels = await discoverOllamaModels(rootURL: rootURLString)
        } else {
            // Try /v1/models (standard OpenAI)
            discoveredModels = await discoverOpenAIModels(rootURL: rootURLString, apiKey: apiKey, headers: customHeaders)

            if discoveredModels.isEmpty && detectedProvider == .unknown {
                // If nothing found yet, try /models
                discoveredModels = await discoverOpenAIModels(rootURL: rootURLString, path: "/models", apiKey: apiKey, headers: customHeaders)
            }
        }

        // STAGE 7 - MODEL NORMALIZATION
        diagnostics.append("Stage 7: Normalizing models...")
        if discoveredModels.isEmpty {
            return .failure("Connection succeeded but no models were discovered.", diagnostics: diagnostics)
        }
        diagnostics.append("Successfully discovered \(discoveredModels.count) models.")

        return LocalModelValidationResult(
            success: true,
            provider: detectedProvider,
            models: discoveredModels,
            error: nil,
            diagnostics: diagnostics
        )
    }

    // MARK: - Discovery Helpers

    private func checkOllama(rootURL: String) async -> Bool {
        guard let url = URL(string: "\(rootURL)/api/tags") else { return false }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["models"] != nil
        } catch {
            return false
        }
    }

    private func checkLMStudio(rootURL: String) async -> Bool {
        // LM Studio often has specific identifiers or we just rely on /v1/models success
        guard let url = URL(string: "\(rootURL)/v1/models") else { return false }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
            // Check if it's LM Studio specifically if possible, otherwise it's just OpenAI compatible
            return true
        } catch {
            return false
        }
    }

    private func discoverOllamaModels(rootURL: String) async -> [AIModel] {
        guard let url = URL(string: "\(rootURL)/api/tags") else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OllamaResponse.self, from: data)
            return response.models.map { m in
                let vision = m.name.lowercased().contains("vision") || m.name.lowercased().contains("llava")
                return AIModel(id: m.name, name: m.name, supportsVision: vision)
            }
        } catch {
            return []
        }
    }

    private func discoverOpenAIModels(rootURL: String, path: String = "/v1/models", apiKey: String = "", headers: [String: String] = [:]) async -> [AIModel] {
        guard let url = URL(string: "\(rootURL)\(path)") else { return [] }
        var request = URLRequest(url: url)
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(OpenAIModelsResponse.self, from: data)
            return response.data.map { m in
                let vision = m.id.lowercased().contains("vision") || m.id.lowercased().contains("vl")
                return AIModel(id: m.id, name: m.id, supportsVision: vision)
            }
        } catch {
            return []
        }
    }

    // MARK: - Chat Execution

    func sendChatRequest(endpoint: String, messages: [ChatMessage], model: String, apiKey: String = "", customHeaders: [String: String] = [:], parameters: [String: Any] = [:]) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw AIError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        customHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        var body: [String: Any] = parameters
        body["model"] = model
        body["messages"] = messages.map { ["role": $0.role, "content": $0.content] }
        body["stream"] = false

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.requestFailed("Server returned \((response as? HTTPURLResponse)?.statusCode ?? -1): \(errorBody)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]

        guard let content = message?["content"] as? String else {
            throw AIError.decodingFailed
        }

        return content
    }
}

// MARK: - Extension for convenience

extension LocalModelValidationResult {
    static func failure(_ error: String, diagnostics: [String]) -> LocalModelValidationResult {
        return LocalModelValidationResult(success: false, provider: .unknown, models: [], error: error, diagnostics: diagnostics + ["FAILED: \(error)"])
    }
}

// MARK: - Internal Response Models

private struct OllamaResponse: Codable {
    let models: [OllamaModel]
}

private struct OllamaModel: Codable {
    let name: String
}

private struct OpenAIModelsResponse: Codable {
    let data: [OpenAIModel]
}

private struct OpenAIModel: Codable {
    let id: String
}
