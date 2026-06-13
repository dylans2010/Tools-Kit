import Foundation
import Combine

public final class BridgeService: ObservableObject {
    public static let shared = BridgeService()

    private let connectionManager = BridgeConnectionManager.shared
    private let sessionManager = BridgeSessionManager.shared

    @Published public private(set) var messages: [BridgeMessage] = []
    @Published public private(set) var pendingCommands: [BridgeCommand] = []

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        connectionManager.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &cancellables)

        connectionManager.commandPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] command in
                self?.pendingCommands.append(command)
            }
            .store(in: &cancellables)
    }

    public func connect(to device: BridgeDevice) async throws {
        await MainActor.run {
            connectionManager.selectDevice(device)
            connectionManager.connect()
        }
    }

    private func handleIncomingMessage(_ message: BridgeMessage) {
        if message.sender == .user {
            messages.append(message)
            return
        }

        // If it's from the host, check if we should append to the last message (streaming)
        if let lastIndex = messages.indices.last,
           messages[lastIndex].sender == .host,
           messages[lastIndex].agentSource == message.agentSource {
            messages[lastIndex].content += message.content
        } else {
            messages.append(message)
        }
    }

    public func sendMessage(_ text: String) -> AsyncStream<String> {
        let userMessage = BridgeMessage(content: text, sender: .user)
        handleIncomingMessage(userMessage)
        connectionManager.sendMessage(text)

        return AsyncStream { continuation in
            let sub = connectionManager.messagePublisher
                .filter { $0.sender == .host }
                .sink { msg in
                    continuation.yield(msg.content)
                    // In a real protocol, the host would send a special "end of stream" message
                    if msg.content.contains("[EOF]") || msg.content.isEmpty {
                        continuation.finish()
                    }
                }

            continuation.onTermination = { @Sendable _ in
                sub.cancel()
            }
        }
    }

    public func testConnection(host: URL, port: Int) async -> Bool {
        var components = URLComponents(url: host, resolvingAgainstBaseURL: true)
        components?.port = port

        guard let finalHostURL = components?.url else { return false }

        let testURL = finalHostURL.appendingPathComponent("health")
        var request = URLRequest(url: testURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    public func executeCommand(_ command: String) async throws -> String {
        // This would typically involve sending a command request and waiting for result
        // For now, it sends a message representing the command
        connectionManager.sendMessage("!exec \(command)")
        return "Command sent for execution"
    }

    public func approveCommand(_ command: BridgeCommand) {
        connectionManager.approveCommand(command)
        pendingCommands.removeAll { $0.id == command.id }
    }

    public func rejectCommand(_ command: BridgeCommand) {
        connectionManager.rejectCommand(command)
        pendingCommands.removeAll { $0.id == command.id }
    }

    public func clearChat() {
        messages = []
    }
}
