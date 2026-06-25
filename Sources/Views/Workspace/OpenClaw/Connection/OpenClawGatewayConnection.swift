import Foundation
import Combine
import UIKit

enum ConnectionState: Equatable {
    case idle
    case connecting
    case socketConnected
    case waitingChallenge
    case authenticating
    case connected
    case failed(String)

    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.connecting, .connecting), (.socketConnected, .socketConnected),
             (.waitingChallenge, .waitingChallenge), (.authenticating, .authenticating), (.connected, .connected):
            return true
        case (.failed(let l), .failed(let r)):
            return l == r
        default:
            return false
        }
    }
}

actor OpenClawGatewayConnection {
    private let url: URL
    private let deviceID: String
    private var socket: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)

    private var _state: ConnectionState = .idle
    private let stateSubject = CurrentValueSubject<ConnectionState, Never>(.idle)

    nonisolated var statePublisher: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private var pendingRequests: [String: CheckedContinuation<AnyCodable, Error>] = [:]

    // External long-lived stream
    private var externalEventStreamContinuation: AsyncStream<OpenClawEvent>.Continuation?

    private var handshakeContinuation: CheckedContinuation<Void, Error>?
    private var heartbeatTimer: Task<Void, Never>?
    private var reconnectionTask: Task<Void, Never>?
    private var connectionAttempt: Int = 0
    private var isManuallyDisconnected: Bool = false

    init(url: URL, deviceID: String) {
        self.url = url
        self.deviceID = deviceID
    }

    private func updateState(_ newState: ConnectionState) {
        _state = newState
        stateSubject.send(newState)
        OpenClawDiagnosticsManager.shared.log("STATE: \(newState)", type: .info)
    }

    func getState() -> ConnectionState { _state }

    func connect() async throws -> AsyncStream<OpenClawEvent> {
        if _state == .connected {
            throw OpenClawError.connectionFailed("Already connected")
        }

        isManuallyDisconnected = false
        reconnectionTask?.cancel()

        // Create the external stream if it doesn't exist
        let (stream, continuation) = AsyncStream.makeStream(of: OpenClawEvent.self)
        self.externalEventStreamContinuation = continuation

        try await performConnect()

        return stream
    }

    private func performConnect() async throws {
        updateState(.connecting)
        socket = session.webSocketTask(with: url)
        socket?.resume()

        updateState(.socketConnected)
        listen()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.handshakeContinuation = continuation

            // OpenClaw Protocol: The first client frame must be a 'connect' request.
            Task {
                do {
                    updateState(.waitingChallenge)
                    _ = try await self.sendRequestInternal("connect", params: [:])
                } catch {
                    self.cleanupHandshake(error: error)
                }
            }

            // Timeout for handshake
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 15s
                await self?.handleHandshakeTimeout()
            }
        }

        updateState(.connected)
        connectionAttempt = 0
        startHeartbeat()
    }

    func disconnect() {
        isManuallyDisconnected = true
        heartbeatTimer?.cancel()
        reconnectionTask?.cancel()
        socket?.cancel(with: .normalClosure, reason: nil)
        updateState(.idle)
        externalEventStreamContinuation?.finish()
        cleanupHandshake(error: OpenClawError.connectionFailed("Disconnected"))
        cleanupAllPendingRequests(error: OpenClawError.connectionFailed("Disconnected"))
    }

    private func handleHandshakeTimeout() {
        if _state == .waitingChallenge || _state == .authenticating {
            cleanupHandshake(error: OpenClawError.connectionTimeout)
            socket?.cancel(with: .abnormalClosure, reason: nil)
            updateState(.failed("Handshake timed out"))
        }
    }

    private func cleanupHandshake(error: Error) {
        handshakeContinuation?.resume(throwing: error)
        handshakeContinuation = nil
    }

    private func cleanupAllPendingRequests(error: Error) {
        for continuation in pendingRequests.values {
            continuation.resume(throwing: error)
        }
        pendingRequests.removeAll()
    }

    func sendRequest(_ method: String, params: [String: AnyCodable] = [:]) async throws -> AnyCodable {
        guard _state == .connected else {
            throw OpenClawError.connectionFailed("Not connected")
        }
        return try await sendRequestInternal(method, params: params)
    }

    private func listen() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            Task {
                await self.handleReceiveResult(result)
            }
        }
    }

    private func handleReceiveResult(_ result: Result<URLSessionWebSocketTask.Message, Error>) async {
        switch result {
        case .success(let message):
            switch message {
            case .data(let data):
                if let text = String(data: data, encoding: .utf8) {
                    OpenClawDiagnosticsManager.shared.log("OPENCLAW INBOUND\n\(text)", type: .protocolMsg)
                }
                await handleIncomingData(data)
            case .string(let text):
                OpenClawDiagnosticsManager.shared.log("OPENCLAW INBOUND\n\(text)", type: .protocolMsg)
                if let data = text.data(using: .utf8) {
                    await handleIncomingData(data)
                }
            @unknown default:
                break
            }
            listen()
        case .failure(let error):
            await handleConnectionFailure(error)
        }
    }

    private func handleConnectionFailure(_ error: Error) async {
        if isManuallyDisconnected { return }

        let errorMsg = error.localizedDescription
        OpenClawDiagnosticsManager.shared.log("Connection failure: \(errorMsg)", type: .error)
        updateState(.failed(errorMsg))
        cleanupHandshake(error: error)
        cleanupAllPendingRequests(error: error)

        scheduleReconnection()
    }

    private func scheduleReconnection() {
        reconnectionTask?.cancel()
        reconnectionTask = Task { [weak self] in
            guard let self = self else { return }

            let attempt = await getAttempt()
            let delay = min(pow(2.0, Double(attempt)), 60.0)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            let manuallyDisconnected = await self.getIsManuallyDisconnected()
            if !Task.isCancelled && !manuallyDisconnected {
                await self.incrementAttempt()
                _ = try? await self.performConnect()
            }
        }
    }

    private func getAttempt() -> Int { connectionAttempt }
    private func incrementAttempt() { connectionAttempt += 1 }
    private func getIsManuallyDisconnected() -> Bool { isManuallyDisconnected }

    private func handleIncomingData(_ data: Data) async {
        // Try decoding as Response
        if let response = try? JSONDecoder().decode(OpenClawRPCResponse.self, from: data), let id = response.id {
            do {
                try response.validate()
            } catch {
                OpenClawDiagnosticsManager.shared.log("Response validation failed: \(error)", type: .error)
            }

            if let continuation = pendingRequests.removeValue(forKey: id) {
                if let error = response.error {
                    continuation.resume(throwing: OpenClawError.protocolError(error.message))
                } else if let result = response.result {
                    // Extract token if present in connect response
                    if _state == .authenticating {
                        if let dict = result.value as? [String: Any], let token = dict["token"] as? String {
                            OpenClawSecureStore.shared.saveToken(token, for: deviceID)
                        }
                    }
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(returning: AnyCodable(NSNull()))
                }
            }
            return
        }

        // Try decoding as Event
        if let event = try? JSONDecoder().decode(OpenClawEvent.self, from: data) {
            externalEventStreamContinuation?.yield(event)

            if event.event == "connect.challenge" {
                await respondToChallenge(event)
            }
            return
        }
    }

    private func respondToChallenge(_ event: OpenClawEvent) async {
        guard _state == .waitingChallenge else { return }
        updateState(.authenticating)

        guard let payload = event.payload.value as? [String: Any],
              let nonce = payload["nonce"] as? String else {
            OpenClawDiagnosticsManager.shared.log("Invalid challenge payload: missing nonce", type: .error)
            cleanupHandshake(error: OpenClawError.invalidNonce)
            return
        }

        let token = OpenClawSecureStore.shared.getToken(for: deviceID)
        let connectParams: [String: AnyCodable] = [
            "nonce": AnyCodable(nonce),
            "token": AnyCodable(token ?? ""),
            "device_id": AnyCodable(deviceID),
            "role": AnyCodable("operator"),
            "metadata": AnyCodable([
                "device_name": UIDevice.current.name,
                "client_id": "com.toolskit.openclaw"
            ])
        ]

        do {
            _ = try await sendRequestInternal("connect", params: connectParams)
            handshakeContinuation?.resume()
            handshakeContinuation = nil
        } catch {
            cleanupHandshake(error: error)
        }
    }

    private func sendRequestInternal(_ method: String, params: [String: AnyCodable]) async throws -> AnyCodable {
        let request = OpenClawRPCRequest(method: method, params: params)

        do {
            try request.validate()
        } catch {
            OpenClawDiagnosticsManager.shared.log("Request validation failed for \(method): \(error)", type: .error)
            throw error
        }

        let data = try JSONEncoder().encode(request)
        let text = String(data: data, encoding: .utf8) ?? "{}"

        OpenClawDiagnosticsManager.shared.log("OPENCLAW OUTBOUND\n\(text)", type: .protocolMsg)

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[request.id] = continuation

            // OpenClaw Gateway requires text frames
            socket?.send(.string(text)) { error in
                if let error = error {
                    Task { [weak self] in
                        await self?.cleanupPendingRequest(request.id, with: error)
                    }
                }
            }

            // Timeout handling for requests
            let requestID = request.id
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30s
                await self?.handleRequestTimeout(requestID)
            }
        }
    }

    private func cleanupPendingRequest(_ id: String, with error: Error) {
        if let continuation = pendingRequests.removeValue(forKey: id) {
            continuation.resume(throwing: error)
        }
    }

    private func handleRequestTimeout(_ id: String) {
        if let continuation = pendingRequests.removeValue(forKey: id) {
            OpenClawDiagnosticsManager.shared.log("Request timed out: \(id)", type: .error)
            continuation.resume(throwing: OpenClawError.requestTimeout)
        }
    }

    private func startHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30s
                guard let self = self else { break }
                if await self.getState() == .connected {
                    _ = try? await self.sendRequest("ping")
                } else {
                    break
                }
            }
        }
    }
}
