import Foundation
import OSLog

public actor QRWebSocketConnection: NSObject, URLSessionWebSocketDelegate {
    private let url: URL
    private var socket: URLSessionWebSocketTask?
    private var session: URLSession?

    public init(url: URL) {
        self.url = url
        super.init()
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    public func connect() {
        socket = session?.webSocketTask(with: url)
        socket?.resume()
    }

    public func disconnect() {
        socket?.cancel(with: .normalClosure, reason: nil)
    }
}
