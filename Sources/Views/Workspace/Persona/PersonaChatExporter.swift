import Foundation
import SwiftUI

struct PersonaAgentActionRecord: Codable, Identifiable {
    let id: UUID
    let triggeredByMessageID: UUID
    let intentCaseName: String
    let parameters: [String: String]
    let result: String // "success" | "failed" | "cancelled"
    let timestamp: Date
}

struct PersonaChatExporter {
    struct ExportRoot: Codable {
        let export_version: String
        let exported_at: String
        let persona: ExportPersona
        let conversation: ExportConversation
        let agent_actions: [ExportAction]
    }

    struct ExportPersona: Codable {
        let id: String
        let name: String
        let model: String
        let agent_mode_enabled: Bool
    }

    struct ExportConversation: Codable {
        let id: String
        let started_at: String
        let message_count: Int
        let messages: [ExportMessage]
    }

    struct ExportMessage: Codable {
        let id: String
        let role: String
        let content: String
        let timestamp: String
        let intent_classified: String?
        let action_taken: String?
        let token_count: Int?
    }

    struct ExportAction: Codable {
        let id: String
        let triggered_by_message_id: String
        let intent: String
        let parameters: [String: String]
        let result: String
        let timestamp: String
    }

    static func export(
        messages: [PersonaMessage],
        actions: [PersonaAgentActionRecord],
        persona: PersonaConfig,
        agentMode: Bool,
        conversationID: UUID,
        includeTokens: Bool = false
    ) throws -> Data {
        let isoFormatter = ISO8601DateFormatter()

        let exportMessages = messages.map { msg in
            ExportMessage(
                id: msg.id.uuidString,
                role: msg.role,
                content: msg.content,
                timestamp: isoFormatter.string(from: msg.timestamp),
                intent_classified: nil,
                action_taken: nil,
                token_count: includeTokens ? msg.content.count / 4 : nil
            )
        }

        let conversation = ExportConversation(
            id: conversationID.uuidString,
            started_at: isoFormatter.string(from: messages.first?.timestamp ?? Date()),
            message_count: messages.count,
            messages: exportMessages
        )

        let exportActions = actions.map { action in
            ExportAction(
                id: action.id.uuidString,
                triggered_by_message_id: action.triggeredByMessageID.uuidString,
                intent: action.intentCaseName,
                parameters: action.parameters,
                result: action.result,
                timestamp: isoFormatter.string(from: action.timestamp)
            )
        }

        let root = ExportRoot(
            export_version: "1.0",
            exported_at: isoFormatter.string(from: Date()),
            persona: .init(
                id: UUID().uuidString, // Persona UUID from config if available
                name: persona.name,
                model: persona.baseModel,
                agent_mode_enabled: agentMode
            ),
            conversation: conversation,
            agent_actions: exportActions
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(root)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
