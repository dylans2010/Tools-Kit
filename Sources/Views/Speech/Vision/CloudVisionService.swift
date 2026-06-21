import Foundation

@MainActor
class CloudVisionService: ObservableObject {
    static let shared = CloudVisionService()

    @Published var selectedProvider: VisionProvider = .openai
    @Published var selectedModel: String = "gpt-4o"
    @Published var isProcessing: Bool = false

    let availableModels: [VisionProvider: [String]] = [
        .openai: ["gpt-4o"],
        .gemini: ["gemini-1.5-pro"]
    ]

    private let keychainService = "com.tools-kit.vision"
    private var inFlightRequest: Bool = false
    private var lastFrameHash: Int?
    private var lastRequestTime: Date?

    private init() {
        loadSettings()
    }

    private func loadSettings() {
        if let savedProvider = UserDefaults.standard.string(forKey: "vision_provider"),
           let provider = VisionProvider(rawValue: savedProvider) {
            self.selectedProvider = provider
        }
        self.selectedModel = UserDefaults.standard.string(forKey: "vision_model") ?? (selectedProvider == .openai ? "gpt-4o" : "gemini-1.5-pro")
    }

    func saveSettings() {
        UserDefaults.standard.set(selectedProvider.rawValue, forKey: "vision_provider")
        UserDefaults.standard.set(selectedModel, forKey: "vision_model")
    }

    func saveKey(_ key: String, for provider: VisionProvider) -> Bool {
        let account = "\(provider.rawValue)_api_key"
        guard let data = key.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    func getKey(for provider: VisionProvider) -> String? {
        let account = "\(provider.rawValue)_api_key"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    func analyzeFrame(_ imageData: Data, history: [SpeechMessage]) async throws -> String {
        let prompt = """
        Perform a detailed analysis of this image. Identify all key objects, read any visible text (OCR),
        and describe the scene's layout and atmosphere concisely.
        Focus heavily on providing specific details that might be relevant to the recent conversation.
        Be natural and conversational in your description.
        """
        return try await analyzeFrameWithPrompt(imageData, prompt: prompt, history: history)
    }

    func analyzeFrameWithPrompt(_ imageData: Data, prompt: String, history: [SpeechMessage]) async throws -> String {
        guard !inFlightRequest else { return "" }
        
        // Stabilize automated requests with a minimum interval
        if let lastTime = lastRequestTime, Date().timeIntervalSince(lastTime) < 2.0 {
            return ""
        }

        let currentHash = imageData.hashValue
        if let last = lastFrameHash, last == currentHash {
            // Frame is visually identical or completely redundant
            return "" // Signal to discard or reuse
        }

        inFlightRequest = true
        isProcessing = true
        lastRequestTime = Date()
        defer {
            inFlightRequest = false
            isProcessing = false
        }

        let providerToTryFirst = selectedProvider
        var response = ""

        SDKLogStore.shared.log("Vision Analysis Request (\(providerToTryFirst.rawValue))", source: "CloudVisionService", level: .info)
        do {
            response = try await performRequest(for: providerToTryFirst, imageData: imageData, prompt: prompt, history: history)
            SDKLogStore.shared.log("Vision Analysis Success (\(providerToTryFirst.rawValue))", source: "CloudVisionService", level: .info)
        } catch {
            SDKLogStore.shared.log("Vision Analysis Failed (\(providerToTryFirst.rawValue)): \(error.localizedDescription)", source: "CloudVisionService", level: .warning)
            print("Vision Service: Primary provider \(providerToTryFirst.rawValue) failed with error: \(error)")
            // Fallback
            let fallbackProvider: VisionProvider = providerToTryFirst == .openai ? .gemini : .openai
            SDKLogStore.shared.log("Vision Analysis Fallback to \(fallbackProvider.rawValue)", source: "CloudVisionService", level: .info)
            print("Vision Service: Attempting fallback to \(fallbackProvider.rawValue)...")
            do {
                response = try await performRequest(for: fallbackProvider, imageData: imageData, prompt: prompt, history: history)
                SDKLogStore.shared.log("Vision Analysis Success (\(fallbackProvider.rawValue))", source: "CloudVisionService", level: .info)
            } catch {
                SDKLogStore.shared.log("Vision Analysis Failed (\(fallbackProvider.rawValue)): \(error.localizedDescription)", source: "CloudVisionService", level: .error)
                print("Vision Service: Fallback provider \(fallbackProvider.rawValue) also failed.")
                throw error
            }
        }
        
        guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw VisionError.apiError("Empty response received")
        }
        
        lastFrameHash = currentHash
        return response
    }
    
    private func performRequest(for provider: VisionProvider, imageData: Data, prompt: String, history: [SpeechMessage]) async throws -> String {
        guard let apiKey = getKey(for: provider) else {
            throw VisionError.missingAPIKey
        }
        
        return try await withRetry {
            switch provider {
            case .openai:
                return try await self.performOpenAIRequest(imageData: imageData, prompt: prompt, apiKey: apiKey, history: history)
            case .gemini:
                return try await self.performGeminiRequest(imageData: imageData, prompt: prompt, apiKey: apiKey, history: history)
            }
        }
    }

    private func withRetry<T>(maxRetries: Int = 3, initialDelay: TimeInterval = 1.0, operation: @escaping () async throws -> T) async throws -> T {
        var currentDelay = initialDelay
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                if attempt == maxRetries - 1 {
                    throw error
                }
                print("Vision Service retry attempt \(attempt + 1) due to error: \(error)")
                try await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
                currentDelay *= 2.0 // Exponential backoff
            }
        }
        throw VisionError.apiError("Retry logic failed")
    }

    private func performOpenAIRequest(imageData: Data, prompt: String, apiKey: String, history: [SpeechMessage]) async throws -> String {
        guard !imageData.isEmpty else {
            throw VisionError.apiError("Image data is empty")
        }

        // Validation: Ensure valid base64
        let base64Image = imageData.base64EncodedString()
        guard !base64Image.isEmpty else {
            throw VisionError.apiError("Failed to encode image to Base64")
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var messages: [[String: Any]] = history.suffix(5).map { ["role": $0.role.rawValue, "content": $0.content] }

        let userContent: [[String: Any]] = [
            ["type": "text", "text": prompt],
            ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
        ]

        messages.append(["role": "user", "content": userContent])

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 500
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VisionError.apiError("No response from OpenAI")
        }

        if httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw VisionError.apiError("OpenAI API error (\(httpResponse.statusCode)): \(body)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        return message?["content"] as? String ?? ""
    }

    private func performGeminiRequest(imageData: Data, prompt: String, apiKey: String, history: [SpeechMessage]) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var contents: [[String: Any]] = []

        // Gemini usually expects user/model alternating, simplified for now
        for msg in history.suffix(5) {
            contents.append([
                "role": msg.role == .assistant ? "model" : "user",
                "parts": [["text": msg.content]]
            ])
        }

        contents.append([
            "role": "user",
            "parts": [
                ["text": prompt],
                ["inlineData": ["mimeType": "image/jpeg", "data": imageData.base64EncodedString()]]
            ]
        ])

        let body: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "maxOutputTokens": 500
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw VisionError.apiError("Gemini API error (status \(statusCode)): \(body)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        return parts?.first?["text"] as? String ?? ""
    }
}

enum VisionError: LocalizedError {
    case missingAPIKey
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Vision API Key is missing. Please check your settings."
        case .apiError(let message):
            return message
        }
    }
}
