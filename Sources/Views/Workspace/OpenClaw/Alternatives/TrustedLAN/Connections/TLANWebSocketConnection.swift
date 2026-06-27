import Foundation
import Network
import OSLog

public enum OpenClawError: Error {
    case notConnected
    case connectionClosed
    case invalidChallenge
    case invalidMessage
    case keychainError(OSStatus)
}

public actor OpenClawTransport {
    private var connection: NWConnection?
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "transport")

    public init() {}

    public func connect(to endpoint: NWEndpoint, using parameters: NWParameters) async throws {
        let conn = NWConnection(to: endpoint, using: parameters)
        self.connection = conn
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    continuation.resume()
                case .failed(let error):
                    continuation.resume(throwing: error)
                case .cancelled:
                    continuation.resume(throwing: CancellationError())
                default:
                    break
                }
            }
            conn.start(queue: .global(qos: .userInitiated))
        }
    }

    public func send(_ data: Data) async throws {
        guard let connection else { throw OpenClawError.notConnected }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            })
        }
    }

    public func receive() async throws -> Data {
        guard let connection else { throw OpenClawError.notConnected }
        return try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                if let error { continuation.resume(throwing: error); return }
                if let data { continuation.resume(returning: data); return }
                if isComplete { continuation.resume(throwing: OpenClawError.connectionClosed) }
            }
        }
    }

    public func disconnect() {
        connection?.cancel()
        connection = nil
    }
}

public actor TLANWebSocketConnection: NSObject, URLSessionWebSocketDelegate {
    private let url: URL; private var socket: URLSessionWebSocketTask?; private var session: URLSession?; private var isSocketOpen = false
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "trusted-lan-ws")
    private var eventContinuation: AsyncStream<Data>.Continuation?

    public init(url: URL) {
        self.url = url; super.init(); let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    public func connect() -> AsyncStream<Data> {
        let (stream, continuation) = AsyncStream.makeStream(of: Data.self); self.eventContinuation = continuation
        socket = session?.webSocketTask(with: url); socket?.resume(); listen(); return stream
    }

    public func disconnect() { socket?.cancel(with: .normalClosure, reason: nil); isSocketOpen = false; eventContinuation?.finish() }

    public func send(data: Data) async throws {
        guard let socket = socket, isSocketOpen else { throw OpenClawError.notConnected }
        try await socket.send(.data(data))
    }

    private func listen() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            Task {
                switch result {
                case .success(let message):
                    switch message {
                    case .data(let data): await self.eventContinuation?.yield(data)
                    case .string(let text): if let data = text.data(using: .utf8) { await self.eventContinuation?.yield(data) }
                    @unknown default: break
                    }
                    await self.listen()
                case .failure(let error):
                    self.logger.error("WS Error: \(error.localizedDescription)")
                    await self.markClosed()
                }
            }
        }
    }

    private func markOpen() { isSocketOpen = true }
    private func markClosed() { isSocketOpen = false; eventContinuation?.finish() }

    public nonisolated func urlSession(_ s: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol p: String?) {
        Task { await self.markOpen() }
    }

    public nonisolated func urlSession(_ s: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith c: URLSessionWebSocketTask.CloseCode, reason r: Data?) {
        Task { await self.markClosed() }
    }
}
