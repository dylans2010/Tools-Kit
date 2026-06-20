import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 17.0, macOS 14.0, *)
@Generable
struct AgenticMetadata: Codable, Sendable {
    var items: [AgenticMetadataItem]
}

@available(iOS 17.0, macOS 14.0, *)
@Generable
struct AgenticMetadataItem: Codable, Sendable {
    var key: String
    var value: String
}

@available(iOS 17.0, macOS 14.0, *)
@Generable
struct AgenticToolOutput {
    var summary: String
    var generatedCode: String?
    var metadata: AgenticMetadata
    var dataPayload: AgenticMetadata
}

@available(iOS 17.0, macOS 14.0, *)
extension AgenticMetadata {
    static var empty: AgenticMetadata {
        return AgenticMetadata(items: [])
    }
}
#endif

struct AgenticToolOutputFallback: Codable, Sendable {
    var summary: String
    var generatedCode: String?
    var metadata: [String: String]
    var dataPayload: [String: String]

    init(summary: String, generatedCode: String? = nil, metadata: [String: String] = [:], dataPayload: [String: String] = [:]) {
        self.summary = summary
        self.generatedCode = generatedCode
        self.metadata = metadata
        self.dataPayload = dataPayload
    }
}
