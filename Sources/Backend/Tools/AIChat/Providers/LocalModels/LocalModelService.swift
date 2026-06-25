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
        diagnostics.append("Endpoint validated: \(endpoint)")

        // STAGE 2 - ROOT URL DERIVATION
        diagnostics.append("Stage 2: Deriving root URL...")
        let rootURLString = "\(url.scheme ?? "http")://\(host)\(url.port != nil ? ":\(url.port!)" : "")"
        guard let rootURL = URL(string: rootURLString) else {
            return .failure("Could not derive root URL from \(endpoint)", diagnostics: diagnostics)
        }
        diagnostics.append("Root URL derived: \(rootURLString)")

        // STAGE 3 - LOCAL PROVIDER DETECTION
        diagnostics.append("Stage 3: Detecting provider...")
        var detectedProvider: LocalProviderType = .unknown

        // Try Ollama detection via root or specific paths
        if await checkOllama(rootURL: rootURLString) {
            detectedProvider = .ollama
            diagnostics.append("Detected provider: \(detectedProvider.rawValue)")

            // STAGE 4 - OLLAMA NATIVE PIPELINE
            diagnostics.append("Stage 4: Executing Ollama native discovery...")
            let ollamaResult = await OllamaConfig.testConnection(endpoint: rootURLString)
            diagnostics.append(contentsOf: ollamaResult.diagnostics)

            if ollamaResult.success {
                return LocalModelValidationResult(
                    success: true,
                    provider: .ollama,
                    models: ollamaResult.models,
                    error: nil,
                    diagnostics: diagnostics
                )
            } else {
                return .failure(ollamaResult.error ?? "Ollama discovery failed", diagnostics: diagnostics)
            }
        }

        // If not Ollama, check for /chat/completions requirement for OpenAI-compatible
        if !url.path.contains("/chat/completions") {
             return .failure("OpenAI-compatible endpoint must end with /chat/completions", diagnostics: diagnostics)
        }

        if await checkLMStudio(rootURL: rootURLString) {
            detectedProvider = .lmStudio
        } else {
            detectedProvider = .openAICompatible
        }
        diagnostics.append("Detected provider: \(detectedProvider.rawValue)")

        // STAGE 5 - MODEL DISCOVERY (OpenAI Compatible)
        diagnostics.append("Stage 5: Discovering models...")
        var discoveredModels: [AIModel] = []

        // Try /v1/models (standard OpenAI)
        discoveredModels = await discoverOpenAIModels(rootURL: rootURLString, apiKey: apiKey, headers: customHeaders)

        if discoveredModels.isEmpty && detectedProvider == .unknown {
            // If nothing found yet, try /models
            discoveredModels = await discoverOpenAIModels(rootURL: rootURLString, path: "/models", apiKey: apiKey, headers: customHeaders)
        }

        // STAGE 6 - MODEL NORMALIZATION
        diagnostics.append("Stage 6: Normalizing models...")
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
            var request = URLRequest(url: url)
            request.timeoutInterval = 3
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["models"] != nil
        } catch {
            return false
        }
    }

    private func checkLMStudio(rootURL: String) async -> Bool {
        guard let url = URL(string: "\(rootURL)/v1/models") else { return false }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 3
            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
            return true
        } catch {
            return false
        }
    }

    private func discoverOpenAIModels(rootURL: String, path: String = "/v1/models", apiKey: String = "", headers: [String: String] = [:]) async -> [AIModel] {
        guard let url = URL(string: "\(rootURL)\(path)") else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
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

private struct OpenAIModelsResponse: Codable {
    let data: [OpenAIModel]
}

private struct OpenAIModel: Codable {
    let id: String
}
