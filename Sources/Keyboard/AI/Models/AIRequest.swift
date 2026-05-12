import Foundation

struct AIRequest: Codable, Sendable {
    let text: String
    let style: RewriteStyle?
    let type: ConversionType?
}

enum RewriteStyle: String, Codable, CaseIterable, Sendable {
    case formal = "Formal"
    case casual = "Casual"
    case friendly = "Friendly"
    case direct = "Direct"
    case concise = "Concise"
    case persuasive = "Persuasive"
    case standard = "Standard"
}

enum ConversionType: String, Codable, CaseIterable, Sendable {
    case email = "Email Response"
    case message = "Message Reply"
    case task = "Task Item"
    case note = "Note Summary"
    case list = "Structured List"
}
