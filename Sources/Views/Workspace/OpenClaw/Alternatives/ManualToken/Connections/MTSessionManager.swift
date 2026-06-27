import Foundation

public actor MTSessionManager {
    public static let shared = MTSessionManager()
    private var connection: MTWebSocketConnection?

    private init() {}

    public func startSession(url: URL) async {
        let connection = MTWebSocketConnection(url: url)
        self.connection = connection
        await connection.connect()
    }

    public func stopSession() async {
        await connection?.disconnect()
        connection = nil
    }
}
