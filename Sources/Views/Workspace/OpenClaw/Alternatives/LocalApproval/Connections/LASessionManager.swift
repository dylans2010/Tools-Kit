import Foundation

public actor LASessionManager {
    public static let shared = LASessionManager()
    private var connection: LAWebSocketConnection?

    private init() {}

    public func startSession(url: URL) async {
        let connection = LAWebSocketConnection(url: url)
        self.connection = connection
        await connection.connect()
    }

    public func stopSession() async {
        await connection?.disconnect()
        connection = nil
    }
}
