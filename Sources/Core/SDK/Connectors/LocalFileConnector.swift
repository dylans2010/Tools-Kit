import Foundation
import UIKit

public class LocalFileConnector: BaseConnector, ObservableObject {
    public let id = UUID()
    public let name = "Local Files"
    public let type: ConnectorType = .localFileSystem
    @Published public var status: ConnectorStatus = .connected
    public var authFields: [AuthField] = []
    @Published public var activityLog: [ConnectorEvent] = []

    public init() {}

    public func authenticate(credentials: [String : String]) async throws {
        // Always connected or uses file picker
    }

    public func sync() async throws {
        // Logic to scan sandbox
    }

    public func testConnection() async throws -> Bool {
        return true
    }

    public func disconnect() {}

    public func importFile(url: URL) throws {
        let sandbox = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = sandbox.appendingPathComponent(url.lastPathComponent)
        try FileManager.default.copyItem(at: url, to: destination)
    }

    public func exportFile(name: String, content: Data) throws -> URL {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try content.write(to: temp)
        return temp
    }
}
