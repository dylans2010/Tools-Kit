import Foundation

struct WorkspaceAIToolDefinition {
    let name: String
    let description: String
    let category: String
    let inputSchema: [String: String]
    let producesCode: Bool
}

struct WorkspaceAITools {
    static let registry: [WorkspaceAIToolDefinition] = [
        WorkspaceAIToolDefinition(
            name: "AgenticToolTaskCreate",
            description: "Creates a new task in the workspace.",
            category: "TASK SYSTEM",
            inputSchema: ["title": "String", "priority": "String", "dueDate": "String"],
            producesCode: false
        ),
        WorkspaceAIToolDefinition(
            name: "AgenticToolNoteSummarize",
            description: "Summarizes a note and extracts key points.",
            category: "NOTES SYSTEM",
            inputSchema: ["noteId": "String", "detailLevel": "String"],
            producesCode: false
        ),
        WorkspaceAIToolDefinition(
            name: "AgenticToolCodeSwiftUIViewGenerator",
            description: "Generates a complete SwiftUI view based on requirements.",
            category: "CODE GENERATION SYSTEM",
            inputSchema: ["viewName": "String", "description": "String"],
            producesCode: true
        ),
        WorkspaceAIToolDefinition(
            name: "AgenticToolAITextSummarize",
            description: "Summarizes long blocks of text into concise bullet points.",
            category: "AI UTILITY SYSTEM",
            inputSchema: ["text": "String", "maxBullets": "String"],
            producesCode: false
        )
    ]
}
