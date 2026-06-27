import Foundation
import Observation
public actor TLANSessionManager {
    public static let shared = TLANSessionManager(); private var connection: TLANWebSocketConnection?
    private init() {}
    public func establishSession(url: URL) async throws {
        let c = TLANWebSocketConnection(url: url); self.connection = c; let stream = await c.connect()
        Task { for await data in stream { OpenClawLoggerService.shared.log(level: .debug, category: .websocket, title: "TLAN Data", description: "Bytes: \(data.count)") } }
    }
    public func disconnect() async { await connection?.disconnect(); connection = nil }
}
