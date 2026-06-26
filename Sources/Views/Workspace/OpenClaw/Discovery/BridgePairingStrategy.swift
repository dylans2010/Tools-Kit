import Foundation

struct BridgePairingStrategy: OpenClawPairingStrategy {
    let name = "Node Bridge"
    let bridgeURL: URL

    func pair() async throws -> OpenClawDevice {
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .pairing,
            title: "Bridge Pairing",
            description: "Initiating pairing via bridge: \(bridgeURL.absoluteString)"
        )
        // 1. Validate Bridge Reachability
        let (data, response) = try await URLSession.shared.data(from: bridgeURL.appendingPathComponent("pair"))
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenClawError.unreachableHost
        }

        // 2. Extract Token and Device Info
        OpenClawLoggerService.shared.log(
            level: .debug,
            category: .http,
            title: "Bridge Response",
            description: "Status: 200, Parsing payload..."
        )
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["token"] as? String,
              let gatewayInfo = json["gateway"] as? [String: Any],
              let host = gatewayInfo["host"] as? String,
              let port = gatewayInfo["port"] as? Int else {
            throw OpenClawError.invalidResponse
        }

        let deviceID = UUID().uuidString

        // CRITICAL: Save token BEFORE attempting validation connection
        OpenClawSecureStore.shared.saveToken(token, for: deviceID)

        // 3. Validate Handshake through Bridge
        let wsURL = URL(string: "ws://\(bridgeURL.host ?? "localhost"):\(bridgeURL.port ?? 3000)")!
        let connection = OpenClawGatewayConnection(url: wsURL, deviceID: deviceID)

        do {
            _ = try await connection.connect()
            await connection.disconnect()
        } catch {
            OpenClawSecureStore.shared.deleteToken(for: deviceID)
            throw OpenClawError.handshakeFailed("Bridge handshake failed: \(error.localizedDescription)")
        }

        // 4. Register Device
        let device = OpenClawDevice(
            id: deviceID,
            name: json["name"] as? String ?? "Bridged Gateway",
            host: host,
            port: port,
            lastConnected: Date(),
            metadata: ["type": "bridge", "bridge": bridgeURL.absoluteString]
        )

        return device
    }
}
