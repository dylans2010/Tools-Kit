import Foundation

final class CustomToolRegistry {
    static let shared = CustomToolRegistry()
    var asAgentTools: [AgentTool] = []
    var connections: [CustomToolConnection] = []
    private init() {}
}

struct CustomToolConnection {
    let agentToolID: String
}

final class ToolExecutor {
    static let shared = ToolExecutor()
    private init() {}
    func execute(toolName: String, parameters: [String: Any]) async throws -> String {
        return "Tool execution stubbed."
    }
}

final class TestToolsManager: ObservableObject {
    static let shared = TestToolsManager()
    private init() {}
    func runAgentToolTests(toolID: String) async {}
    func runExtensionTests(extensionID: String) async {}
}

final class DocumentationAnalyzer: ObservableObject {
    static let shared = DocumentationAnalyzer()
    private init() {}
    func analyze(url: URL, documentationContent: String?) async {}
}

final class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()
    @Published var proAccess: Bool = true
    private init() {}
}

final class OnDeviceModelRouter {
    static let shared = OnDeviceModelRouter()
    private init() {}
    func useOnDeviceAI() -> Bool { return false }
    func generateResponse(prompt: String, useContext: Bool) async throws -> LLMResponse {
        throw LLMError.modelNotFound
    }
}

struct PaywallView: SwiftUI.View {
    var body: some SwiftUI.View { SwiftUI.Text("Paywall") }
}

struct DocumentationAIInsightsView: SwiftUI.View {
    var body: some SwiftUI.View { SwiftUI.Text("AI Insights") }
}

struct LLMResponse {
    let modelName: String
    let completionText: String
    let tokenUsage: TokenUsage?
    let latency: TimeInterval
    struct TokenUsage {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
    }
}
