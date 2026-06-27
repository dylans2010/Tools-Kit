import Foundation

public actor PCSessionManager {
    public static let shared = PCSessionManager()
    private var connection: PCWebSocketConnection?

    private init() {}

    public func startSession(url: URL) async {
        let connection = PCWebSocketConnection(url: url)
        self.connection = connection
        await connection.connect()
    }

    public func stopSession() async {
        await connection?.disconnect()
        connection = nil
    }
}
