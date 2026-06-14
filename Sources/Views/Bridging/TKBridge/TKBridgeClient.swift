import Foundation
import SwiftUI
import Combine
import Network
import Security

public enum TKBridgeConnectionState: Equatable {
    case disconnected
    case discovering
    case hostFound(String, String) // IP, Code
    case pairing
    case connected(TKBridgeDevice)
    case reconnecting
    case failed(String)
}

public struct TKBridgeDevice: Codable, Equatable {
    public let name: String
    public let hostname: String
    public let ip: String
    public let os: String
    public let version: String
    public let architecture: String

    enum CodingKeys: String, CodingKey {
        case name = "device_name"
        case hostname
        case ip
        case os
        case version = "os_version"
        case architecture = "arch"
    }
}

public final class TKBridgeClient: ObservableObject {
    public static let shared = TKBridgeClient()

    @Published public private(set) var state: TKBridgeConnectionState = .disconnected
    @Published public private(set) var activeDevice: TKBridgeDevice?

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var heartbeatTimer: Timer?
    private var reconnectTimer: Timer?

    private let sessionService = "com.toolskit.tkbridge"
    private let tokenAccount = "session_token"
    private let hostKey = "com.toolskit.tkbridge.host_ip"

    private var listener: NWListener?
    private var connection: NWConnection?

    private init() {
        self.urlSession = URLSession(configuration: .default)
        attemptSilentReconnect()
    }

    // MARK: - Discovery

    public func startDiscovery() {
        state = .discovering

        let port = NWEndpoint.Port(integerLiteral: 8730)
        let parameters = NWParameters.udp

        do {
            listener = try NWListener(using: parameters, on: port)
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleDiscoveryConnection(connection)
            }
            listener?.stateUpdateHandler = { state in
                if case .failed(let error) = state {
                    print("Discovery listener failed: \(error)")
                }
            }
            listener?.start(queue: .main)

            // Broadcast discovery request
            broadcastDiscovery()
        } catch {
            print("Failed to start discovery listener: \(error)")
            state = .failed("Discovery failed to start")
        }
    }

    private func broadcastDiscovery() {
        let port = NWEndpoint.Port(integerLiteral: 8730)
        let connection = NWConnection(host: .ipv4(.any), port: port, using: .udp)
        connection.start(queue: .main)

        let message = "TKBRIDGE_DISCOVER".data(using: .utf8)!
        connection.send(content: message, completion: .contentProcessed { error in
            if let error = error {
                print("Broadcast failed: \(error)")
            }
            connection.cancel()
        })
    }

    private func handleDiscoveryConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            if let data = data, let response = try? JSONDecoder().decode(DiscoveryResponse.self, from: data) {
                DispatchQueue.main.async {
                    self?.state = .hostFound(response.ip, response.pairing_code)
                    self?.listener?.cancel()
                }
            }
        }
    }

    struct DiscoveryResponse: Codable {
        let ip: String
        let pairing_code: String
    }

    // MARK: - Connection

    public func pair(host: String, code: String) {
        state = .pairing
        let wsURL = URL(string: "ws://\(host):8732")!
        connect(to: wsURL, pairingCode: code)
    }

    private func connect(to url: URL, pairingCode: String? = nil, token: String? = nil) {
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()

        if let code = pairingCode {
            send(json: ["type": "pair", "code": code])
        } else if let token = token {
            send(json: ["type": "auth", "token": token])
        }

        startHeartbeat()
    }

    private func send(json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let string = String(data: data, encoding: .utf8) else { return }

        webSocketTask?.send(.string(string)) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                DispatchQueue.main.async {
                    self?.handleDisconnect()
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        DispatchQueue.main.async {
            if let type = json["type"] as? String {
                switch type {
                case "tkbridge_connected":
                    if let deviceData = try? JSONSerialization.data(withJSONObject: json["device"] as Any),
                       let device = try? JSONDecoder().decode(TKBridgeDevice.self, from: deviceData) {
                        self.activeDevice = device
                        self.state = .connected(device)

                        if let token = json["token"] as? String {
                            self.saveToken(token)
                            UserDefaults.standard.set(device.ip, forKey: self.hostKey)
                        }
                    }
                case "error":
                    self.state = .failed(json["message"] as? String ?? "Unknown error")
                default:
                    break
                }
            }
        }
    }

    private func handleDisconnect() {
        if case .connected = state {
            state = .reconnecting
            scheduleReconnect()
        } else {
            state = .disconnected
        }
        stopHeartbeat()
    }

    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.attemptSilentReconnect()
        }
    }

    public func attemptSilentReconnect() {
        guard let token = loadToken(),
              let host = UserDefaults.standard.string(forKey: hostKey) else {
            state = .disconnected
            return
        }

        let wsURL = URL(string: "ws://\(host):8732")!
        connect(to: wsURL, token: token)
    }

    public func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        state = .disconnected
        activeDevice = nil
        deleteToken()
        UserDefaults.standard.removeObject(forKey: hostKey)
        stopHeartbeat()
    }

    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if error != nil {
                    self?.handleDisconnect()
                }
            }
        }
    }

    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    // MARK: - Keychain

    private func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: sessionService,
            kSecAttrAccount as String: tokenAccount,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: sessionService,
            kSecAttrAccount as String: tokenAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    private func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: sessionService,
            kSecAttrAccount as String: tokenAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
