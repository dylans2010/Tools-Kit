import Foundation

@MainActor
class LMConnectionManager: ObservableObject {
    static let shared = LMConnectionManager()

    @Published var selectedDevice: LMDevice?
    @Published var selectedModel: LMModel?
    @Published var isConnecting = false
    @Published var lastError: String?

    private let client = LMNetworkClient()

    func selectDevice(_ device: LMDevice) {
        self.selectedDevice = device
        if let firstModel = device.models.first {
            self.selectedModel = firstModel
        }
    }

    func selectModel(_ model: LMModel) {
        self.selectedModel = model
    }

    func sendChatRequest(prompt: String, systemPrompt: String = "") async throws -> String {
        // STRICT VALIDATION BEFORE EXECUTION
        guard let device = selectedDevice else {
            throw AIError.deviceOffline
        }

        // Verify reachability before sending request
        if !await checkDeviceReachability(device) {
            throw AIError.deviceOffline
        }

        guard let model = selectedModel else {
            throw AIError.noModelSelected
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

        // Implement simple retry logic
        var lastErr: Error?
        for attempt in 1...2 {
            do {
                let (data, response) = try await client.postRaw(url, body: body, timeout: 30.0)

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw AIError.requestFailed(errorMsg)
                }

                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let choices = json?["choices"] as? [[String: Any]]
                let message = choices?.first?["message"] as? [String: Any]

                guard let content = message?["content"] as? String else {
                    throw AIError.decodingFailed
                }

                return content
            } catch {
                lastErr = error
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s wait before retry
                }
            }
        }

        throw lastErr ?? AIError.requestFailed("All attempts failed")
    }

    func fetchModelsForSelectedDevice() async {
        guard let device = selectedDevice else { return }

        let url = URL(string: "\(device.baseURL)/v1/models")!
        do {
            let response: LMModelsResponse = try await client.request(url, timeout: 5.0)

            // STRICT PARSING AND DEDUPLICATION
            let models = response.data
                .map { LMModel(id: $0.id) }
                .reduce(into: [LMModel]()) { uniqueModels, model in
                    if !uniqueModels.contains(where: { $0.id == model.id }) {
                        uniqueModels.append(model)
                    }
                }

            await MainActor.run {
                self.selectedDevice?.models = models
                if self.selectedModel == nil || !models.contains(where: { $0.id == self.selectedModel?.id }) {
                    self.selectedModel = models.first
                }
            }
        } catch {
            await MainActor.run {
                self.lastError = "Failed to fetch models: \(error.localizedDescription)"
            }
        }
    }

    private func checkDeviceReachability(_ device: LMDevice) async -> Bool {
        let url = URL(string: "\(device.baseURL)/v1/models")!
        do {
            let _: LMModelsResponse = try await client.request(url, timeout: 2.0)
            return true
        } catch {
            return false
        }
    }
}
