import Foundation

public enum PolicySeverity: String, Codable, CaseIterable {
    case info = "Info"
    case warning = "Warning"
    case critical = "Critical"
}

public struct SecurityPolicy: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var description: String
    public var isCompliant: Bool
    public var severity: PolicySeverity

    public init(id: UUID = UUID(), name: String, description: String, isCompliant: Bool = true, severity: PolicySeverity = .info) {
        self.id = id
        self.name = name
        self.description = description
        self.isCompliant = isCompliant
        self.severity = severity
    }
}
