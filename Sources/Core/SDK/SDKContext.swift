import Foundation

/// Runtime context for the WorkspaceSDK.
/// Holds stateful information about the current execution environment.
public final class SDKContext {
    public let id: UUID
    public let startTime: Date
    public var metadata: [String: Any]

    public init(id: UUID = UUID(), startTime: Date = Date(), metadata: [String: Any] = [:]) {
        self.id = id
        self.startTime = startTime
        self.metadata = metadata
    }

    public static let `default` = SDKContext()
}
