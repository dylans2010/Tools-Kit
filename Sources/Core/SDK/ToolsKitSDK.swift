import Foundation
import Combine

public class ToolsKitSDK: ObservableObject {
    public static let shared = ToolsKitSDK()

    public var isInitialized: Bool = false

    private init() {}

    public func writeData(_ item: SDKDataItem, scope: SDKScope) async throws -> SDKWriteResult {
        return .success
    }

    public func writeData(scope: SDKScope, title: String, payload: [String: String]) async throws -> SDKWriteResult {
        return .success
    }

    public func validateScope(_ scope: SDKScope) -> Bool {
        return true
    }

    public func validateScope(scope: SDKScope, operation: SDKScopeOperation) -> Bool {
        return true
    }

    public func fetchData(scope: SDKScope) async throws -> [SDKDataItem] {
        return []
    }

    public func externalFetch(url: String) async throws -> Data {
        return Data()
    }
}

public enum SDKScopeOperation {
    case read, write, execute
}
