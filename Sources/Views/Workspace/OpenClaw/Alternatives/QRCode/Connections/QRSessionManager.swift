import Foundation

public actor QRSessionManager {
    public static let shared = QRSessionManager()
    private var connection: QRWebSocketConnection?

    private init() {}

    public func startSession(url: URL) async {
        let connection = QRWebSocketConnection(url: url)
        self.connection = connection
        await connection.connect()
    }

    public func stopSession() async {
        await connection?.disconnect()
        connection = nil
    }
}
