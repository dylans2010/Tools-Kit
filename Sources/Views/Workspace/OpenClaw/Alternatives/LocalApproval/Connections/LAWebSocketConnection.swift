import Foundation
import OSLog

public actor LAWebSocketConnection: NSObject, URLSessionWebSocketDelegate {
    private let url: URL
    private var socket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var isSocketOpen = false
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "local-approval-ws")
    private var eventContinuation: AsyncStream<Data>.Continuation?

    public init(url: URL) {
        self.url = url
        super.init()
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    public func connect() -> AsyncStream<Data> {
        let (stream, continuation) = AsyncStream.makeStream(of: Data.self)
        self.eventContinuation = continuation
        socket = session?.webSocketTask(with: url)
        socket?.resume()
        listen()
        return stream
    }

    public func disconnect() {
        socket?.cancel(with: .normalClosure, reason: nil)
        isSocketOpen = false
        eventContinuation?.finish()
    }

    public func send(data: Data) async throws {
        guard let socket = socket, isSocketOpen else {
            throw LocalApprovalError.connectionFailed("Socket not open")
        }
        try await socket.send(.data(data))
    }

    private func listen() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            Task {
                switch result {
                case .success(let message):
                    switch message {
                    case .data(let data):
                        await self.eventContinuation?.yield(data)
                    case .string(let text):
                        if let data = text.data(using: .utf8) {
                            await self.eventContinuation?.yield(data)
                        }
                    @unknown default:
                        break
                    }
                    await self.listen()
                case .failure(let error):
                    self.logger.error("LA WS Error: \(error.localizedDescription)")
                    await self.markClosed()
                }
            }
        }
    }

    private func markOpen() {
        isSocketOpen = true
    }

    private func markClosed() {
        isSocketOpen = false
        eventContinuation?.finish()
    }

    public nonisolated func urlSession(_ s: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol p: String?) {
        Task {
            await self.markOpen()
        }
    }

    public nonisolated func urlSession(_ s: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith c: URLSessionWebSocketTask.CloseCode, reason r: Data?) {
        Task {
            await self.markClosed()
        }
    }
}
