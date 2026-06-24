import Foundation
import OSLog

actor OpenClawGatewayConnection {
    private let url: URL
    private var webSocket: URLSessionWebSocketTask?
    private let logger = Logger(subsystem: "com.toolskit.openclaw", category: "Connection")

    private var pendingRequests: [String: CheckedContinuation<OpenClawResponse, Error>] = [:]
    private var eventContinuations: [AsyncStream<OpenClawEvent>.Continuation] = []

    private(set) var isConnected = false
    private var currentToken: String?

    init(url: URL) {
        self.url = url
    }

    func connect(token: String) async throws {
        self.currentToken = token
        try await performConnect()
    }

    private func performConnect() async throws {
        guard let token = currentToken else { throw OpenClawConnectionError.handshakeFailed }

        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        isConnected = true

        startReceiving()

        try await performHandshake(token: token)
    }

    func disconnect() {
        isConnected = false
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil

        for cont in pendingRequests.values {
            cont.resume(throwing: OpenClawConnectionError.disconnected)
        }
        pendingRequests.removeAll()

        for cont in eventContinuations {
            cont.finish()
        }
        eventContinuations.removeAll()
    }

    func sendRequest(_ method: String, params: [String: Any] = [:]) async throws -> OpenClawResponse {
        guard isConnected else { throw OpenClawConnectionError.notConnected }

        let id = UUID().uuidString
        let request = OpenClawRequest(id: id, method: method, params: params.mapValues { AnyCodable($0) })
        let data = try JSONEncoder().encode(request)

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[id] = continuation

            guard let webSocket = self.webSocket else {
                continuation.resume(throwing: OpenClawConnectionError.notConnected)
                return
            }

            webSocket.send(.data(data)) { error in
                if let error = error {
                    Task {
                        await self.handleSendFailure(id: id, error: error)
                    }
                }
            }
        }
    }

    private func handleSendFailure(id: String, error: Error) {
        if let continuation = pendingRequests.removeValue(forKey: id) {
            continuation.resume(throwing: error)
        }
    }

    func events() -> AsyncStream<OpenClawEvent> {
        AsyncStream { continuation in
            Task {
                await registerContinuation(continuation)
            }
        }
    }

    private func registerContinuation(_ continuation: AsyncStream<OpenClawEvent>.Continuation) {
        eventContinuations.append(continuation)

        continuation.onTermination = { [weak self] _ in
            Task { [weak self] in
                await self?.removeContinuation(continuation)
            }
        }
    }

    private func removeContinuation(_ continuation: AsyncStream<OpenClawEvent>.Continuation) {
        eventContinuations.removeAll { $0 === continuation }
    }

    private func startReceiving() {
        Task { [weak self] in
            while true {
                guard let self = self,
                      let webSocket = await self.webSocket,
                      await self.isConnected else { break }

                do {
                    let message = try await webSocket.receive()
                    await self.handleIncomingMessage(message)
                } catch {
                    await self.handleConnectionFailure(error)
                    break
                }
            }
        }
    }

    private func handleIncomingMessage(_ message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .string(let text):
            guard let d = text.data(using: .utf8) else { return }
            data = d
        case .data(let d):
            data = d
        @unknown default:
            return
        }

        let decoder = JSONDecoder()
        if let response = try? decoder.decode(OpenClawResponse.self, from: data) {
            if let continuation = pendingRequests.removeValue(forKey: response.id) {
                continuation.resume(returning: response)
            }
        } else if let errorResponse = try? decoder.decode(OpenClawError.self, from: data) {
            if let id = errorResponse.id, let continuation = pendingRequests.removeValue(forKey: id) {
                continuation.resume(throwing: OpenClawConnectionError.rpcError(errorResponse.error.message))
            }
        } else if let event = try? decoder.decode(OpenClawEvent.self, from: data) {
            for cont in eventContinuations {
                cont.yield(event)
            }
        }
    }

    private func handleConnectionFailure(_ error: Error) {
        logger.error("Connection failure: \(error.localizedDescription)")
        if isConnected {
            // Trigger reconnection
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if isConnected {
                    try? await performConnect()
                }
            }
        }
    }

    private func performHandshake(token: String) async throws {
        let nonce = try await waitForChallenge()

        let response = try await sendRequest("connect", params: [
            "role": "operator",
            "auth": ["token": token],
            "device": ["nonce": nonce],
            "client": [
                "id": "tools-kit-ios",
                "version": "1.1.704",
                "platform": "iOS"
            ]
        ])

        guard response.type == "res" else {
            throw OpenClawConnectionError.handshakeFailed
        }

        logger.info("Handshake successful")
    }

    private func waitForChallenge() async throws -> String {
        return try await withTimeout(seconds: 10) {
            for await event in self.events() {
                if event.event == "connect.challenge",
                   let data = event.data?.value as? [String: Any],
                   let nonce = data["nonce"] as? String {
                    return nonce
                }
            }
            throw OpenClawConnectionError.handshakeFailed
        }
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw OpenClawConnectionError.timeout
            }
            guard let result = try await group.next() else {
                throw OpenClawConnectionError.timeout
            }
            group.cancelAll()
            return result
        }
    }
}

enum OpenClawConnectionError: Error {
    case notConnected
    case disconnected
    case rpcError(String)
    case handshakeFailed
    case timeout
}
