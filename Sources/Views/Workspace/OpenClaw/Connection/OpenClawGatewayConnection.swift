import Foundation
import Combine

enum ConnectionState {
    case idle
    case connecting
    case authenticating
    case connected
    case failed(Error)
}

actor OpenClawGatewayConnection {
    private let url: URL
    private let deviceID: String
    private var socket: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)

    private(set) var state: ConnectionState = .idle
    private var pendingRequests: [String: CheckedContinuation<AnyCodable, Error>] = [:]
    private var eventStreamContinuation: AsyncStream<OpenClawEvent>.Continuation?
    private var handshakeContinuation: CheckedContinuation<Void, Error>?

    private var heartbeatTimer: Task<Void, Never>?

    init(url: URL, deviceID: String) {
        self.url = url
        self.deviceID = deviceID
    }

    func connect() async throws -> AsyncStream<OpenClawEvent> {
        guard await getState() == .idle || isFailed() else {
            throw OpenClawError.connectionFailed("Already connecting or connected")
        }

        await setState(.connecting)
        socket = session.webSocketTask(with: url)
        socket?.resume()

        let (stream, continuation) = AsyncStream.makeStream(of: OpenClawEvent.self)
        self.eventStreamContinuation = continuation

        listen()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.handshakeContinuation = continuation
            self.state = .authenticating

            // Timeout for handshake
            Task { [weak self] in
                guard let self = self else { return }
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10s
                await self.handleHandshakeTimeout()
            }
        }

        await setState(.connected)
        startHeartbeat()

        return stream
    }

    private func getState() -> ConnectionState { state }
    private func isFailed() -> Bool {
        if case .failed = state { return true }
        return false
    }
    private func setState(_ newState: ConnectionState) { self.state = newState }

    private func handleHandshakeTimeout() {
        if let handshake = self.handshakeContinuation {
            self.handshakeContinuation = nil
            handshake.resume(throwing: OpenClawError.authenticationFailed("Handshake timed out"))
        }
    }

    func disconnect() {
        heartbeatTimer?.cancel()
        socket?.cancel(with: .normalClosure, reason: nil)
        state = .idle
        eventStreamContinuation?.finish()
        if let handshake = handshakeContinuation {
            handshake.resume(throwing: OpenClawError.connectionFailed("Disconnected"))
            handshakeContinuation = nil
        }
    }

    func sendRequest(_ method: String, params: [String: AnyCodable] = [:]) async throws -> AnyCodable {
        guard case .connected = state else {
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
                await handleIncomingData(data)
            case .string(let text):
                if let data = text.data(using: .utf8) {
                    await handleIncomingData(data)
                }
            @unknown default:
                break
            }
            listen()
        case .failure(let error):
            state = .failed(error)
            eventStreamContinuation?.finish()
            if let handshake = handshakeContinuation {
                handshake.resume(throwing: error)
                handshakeContinuation = nil
            }
        }
    }

    private func handleIncomingData(_ data: Data) async {
        // Try decoding as Response
        if let response = try? JSONDecoder().decode(OpenClawRPCResponse.self, from: data), let id = response.id {
            if let continuation = pendingRequests.removeValue(forKey: id) {
                if let error = response.error {
                    continuation.resume(throwing: OpenClawError.protocolError(error.message))
                } else if let result = response.result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(returning: AnyCodable(NSNull()))
                }
            }
            return
        }

        // Try decoding as Event
        if let event = try? JSONDecoder().decode(OpenClawEvent.self, from: data) {
            eventStreamContinuation?.yield(event)

            // Special case: challenge during handshake
            if event.event == "connect.challenge", case .authenticating = state {
                await respondToChallenge(event)
            }
            return
        }
    }

    private func respondToChallenge(_ event: OpenClawEvent) async {
        guard let payload = event.payload.value as? [String: Any],
              let nonce = payload["nonce"] as? String else {
            let error = OpenClawError.authenticationFailed("Missing nonce")
            handshakeContinuation?.resume(throwing: error)
            handshakeContinuation = nil
            return
        }

        let connectParams: [String: AnyCodable] = [
            "nonce": AnyCodable(nonce),
            "role": AnyCodable("operator"),
            "metadata": AnyCodable([
                "device_name": "iPhone",
                "client_id": "com.toolskit.openclaw"
            ])
        ]

        do {
            _ = try await sendRequestInternal("connect", params: connectParams)
            handshakeContinuation?.resume()
            handshakeContinuation = nil
        } catch {
            handshakeContinuation?.resume(throwing: error)
            handshakeContinuation = nil
        }
    }

    private func sendRequestInternal(_ method: String, params: [String: AnyCodable]) async throws -> AnyCodable {
        let request = OpenClawRPCRequest(method: method, params: params)
        let data = try JSONEncoder().encode(request)

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[request.id] = continuation
            socket?.send(.data(data)) { error in
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
            continuation.resume(throwing: OpenClawError.requestTimeout)
        }
    }

    private func startHeartbeat() {
        heartbeatTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard let self = self else { break }
                _ = try? await self.sendRequest("ping")
            }
        }
    }
}
