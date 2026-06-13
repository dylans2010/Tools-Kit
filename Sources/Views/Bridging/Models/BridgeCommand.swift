import Foundation

public struct BridgeCommand: Codable, Identifiable, Equatable {
    public let id: UUID
    public let executable: String
    public let arguments: [String]
    public let workingDirectory: String?
    public var status: Status

    public enum Status: String, Codable {
        case pending
        case approved
        case rejected
        case executing
        case completed
        case failed
    }

    public var fullCommand: String {
        ([executable] + arguments).joined(separator: " ")
    }

    public init(id: UUID = UUID(), executable: String, arguments: [String], workingDirectory: String? = nil, status: Status = .pending) {
        self.id = id
        self.executable = executable
        self.arguments = arguments
        self.workingDirectory = workingDirectory
        self.status = status
    }
}
