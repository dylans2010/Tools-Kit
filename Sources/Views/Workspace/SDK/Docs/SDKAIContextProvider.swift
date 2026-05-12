import Foundation

/// Single-source-of-truth context provider for all AI-driven SDK features.
/// Loads SDK_AI_System.md and constructs constrained system prompts from it.
/// No external knowledge, hardcoded prompts, or fallback sources are permitted.
enum SDKAIContextProvider: Sendable {

    /// Load the SDK_AI_System.md document from the app bundle.
    /// Returns the full document content or an error notice if unavailable.
    static func loadContext() -> String {
        if let url = Bundle.main.url(forResource: "SDK_AI_System", withExtension: "md"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            return content
        }
        return "[SDK_AI_System.md could not be loaded from the app bundle. AI context is unavailable.]"
    }

    /// Construct the system prompt for SDKHelpView.
    /// The AI acts as a constrained interpretive assistant reading only SDK_AI_System.md.
    static func helpSystemPrompt(context: String) -> String {
        return """
        You are the ToolsKit SDK Help Assistant. Your behavior is strictly constrained:

        RULES:
        - You may ONLY answer questions using the SDK documentation provided below.
        - You must NOT infer, assume, or generate knowledge outside this document.
        - If the answer is not contained in the document, say so explicitly.
        - Answer concisely and practically for mobile iOS developers using SwiftUI.
        - Use Markdown formatting: headings, bullet lists, code blocks, and tables where appropriate.
        - When referencing SDK types, use inline code formatting.

        SDK DOCUMENTATION (ONLY AUTHORIZED KNOWLEDGE SOURCE):

        \(context)
        """
    }

    /// Construct the system prompt for SDKSupportView.
    /// The AI acts as a constrained generation system producing SDK-compliant structures only.
    static func supportSystemPrompt(context: String) -> String {
        return """
        You are the ToolsKit SDK App Architect. Your behavior is strictly constrained:

        RULES:
        - You may ONLY generate SDK-compliant application plans using the SDK documentation provided below.
        - All generated modules, connectors, plugins, and automation rules must use types, capabilities, and patterns defined in this document.
        - You must NOT introduce external frameworks, unknown patterns, or capabilities not defined in the SDK documentation.
        - Output ONLY a JSON object with this structure (no markdown, no explanation):
        {"appName":"string","description":"string","modules":[{"name":"string","capabilities":["string"],"description":"string"}],"connectors":[{"name":"string","type":"string","purpose":"string"}],"plugins":[{"name":"string","category":"string","hooks":["string"]}],"automationRules":["string"],"complexity":"Low|Medium|High"}
        - Valid module capabilities: dataAccess, networking, storage, rendering, automation, authentication, analytics, messaging, fileSystem, aiProcessing, connectorBinding, pluginHosting, eventPublishing, backgroundExecution
        - Valid connector types: gmail, webhook, github, localFileSystem, calendar
        - Valid plugin categories: productivity, communication, development, analytics, automation, integration, utility, ai
        - Valid automation triggers: dataUpdated, connectorEvent, timeBased
        - Valid automation actions: runTool, syncConnector, sendNotification, exportData

        SDK DOCUMENTATION (ONLY AUTHORIZED KNOWLEDGE SOURCE):

        \(context)
        """
    }
}
