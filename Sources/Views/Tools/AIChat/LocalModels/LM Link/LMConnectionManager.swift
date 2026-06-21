import Foundation

@MainActor
class LMConnectionManager: ObservableObject {
    static let shared = LMConnectionManager()

    @Published var selectedDevice: LMDevice?
    @Published var selectedModel: LMModel?
    @Published var isConnecting = false
    @Published var lastError: String?

    private let client = LMNetworkClient()
    private let monitor = LMDeviceMonitorService()

    func selectDevice(_ device: LMDevice) {
        self.selectedDevice = device
        self.selectedModel = device.models.first
    }

    func selectModel(_ model: LMModel) {
        self.selectedModel = model
    }

    func sendChatRequest(prompt: String, systemPrompt: String = "") async throws -> String {
        guard let device = selectedDevice else {
            throw NSError(domain: "LMConnectionManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No device selected"])
        }

        guard let model = selectedModel else {
            throw NSError(domain: "LMConnectionManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No model selected"])
        }

        let url = URL(string: "\(device.baseURL)/v1/chat/completions")!

        var messages: [[String: String]] = []
        if !systemPrompt.isEmpty {
            messages.append(["role": "system", "content": systemPrompt])
        }
        messages.append(["role": "user", "content": prompt])

        let payload: [String: Any] = [
            "model": model.id,
            "messages": messages,
            "temperature": 0.7,
            "stream": false
        ]

        let body = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await client.postRaw(url, body: body)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "LMConnectionManager", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]

        guard let content = message?["content"] as? String else {
            throw NSError(domain: "LMConnectionManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }

        return content
    }

    func fetchModelsForSelectedDevice() async {
        guard let device = selectedDevice else { return }

        let url = URL(string: "\(device.baseURL)/v1/models")!
        do {
            let response: LMModelsResponse = try await client.request(url)
            self.selectedDevice?.models = response.data.map { LMModel(id: $0.id) }
        } catch {
            self.lastError = "Failed to fetch models: \(error.localizedDescription)"
        }
    }
}
