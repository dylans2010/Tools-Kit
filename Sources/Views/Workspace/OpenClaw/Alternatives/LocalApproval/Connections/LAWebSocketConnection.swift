import Foundation

public actor LAWebSocketConnection: NSObject, URLSessionWebSocketDelegate {
    private let url: URL
    private var socket: URLSessionWebSocketTask?

    public init(url: URL) {
        self.url = url
    }

    public func connect() {
        socket = URLSession.shared.webSocketTask(with: url)
        socket?.resume()
    }

    public func disconnect() {
        socket?.cancel(with: .normalClosure, reason: nil)
    }
}
