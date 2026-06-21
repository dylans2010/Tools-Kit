import Foundation

@MainActor
class VisionService: ObservableObject {
    static let shared = VisionService()

    @Published var selectedProvider: VisionProvider = .openai
    @Published var selectedModel: String = "gpt-4o"
    @Published var isProcessing: Bool = false

    let availableModels: [VisionProvider: [String]] = [
        .openai: ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo"],
        .gemini: ["gemini-1.5-pro", "gemini-1.5-flash", "gemini-2.0-flash-exp"]
    ]

    private let keychainService = "com.tools-kit.vision"
    private var inFlightRequest: Bool = false

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
        guard !inFlightRequest else { return "" }

        inFlightRequest = true
        isProcessing = true
        defer {
            inFlightRequest = false
            isProcessing = false
        }

        guard let apiKey = getKey(for: selectedProvider) else {
            throw VisionError.missingAPIKey
        }

        let prompt = "What do you see in this image? Provide a concise description that fits a conversation context."

        return try await withRetry {
            switch self.selectedProvider {
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
        // Validation: Ensure valid base64
        let base64Image = imageData.base64EncodedString()
        guard !base64Image.isEmpty else {
            throw VisionError.apiError("Invalid image data")
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
            "model": selectedModel,
            "messages": messages,
            "max_tokens": 300
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw VisionError.apiError("OpenAI API error")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        return message?["content"] as? String ?? ""
    }

    private func performGeminiRequest(imageData: Data, prompt: String, apiKey: String, history: [SpeechMessage]) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModel):generateContent?key=\(apiKey)")!
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

        let body: [String: Any] = ["contents": contents]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw VisionError.apiError("Gemini API error")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        return parts?.first?["text"] as? String ?? ""
    }
}

enum VisionError: Error {
    case missingAPIKey
    case apiError(String)
}
