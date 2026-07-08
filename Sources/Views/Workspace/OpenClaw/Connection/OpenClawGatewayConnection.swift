import Foundation
#if canImport(UIKit)
import UIKit
#endif
import OSLog
import CryptoKit

private let logger = Logger(subsystem: "com.toolskit.openclaw", category: "handshake")

private extension Logger {
    static let ws = Logger(subsystem: "com.toolskit.openclaw", category: "websocket")
}

public enum OpenClawFailureReason: Equatable {
    case missingToken
    case emptyToken
    case invalidToken
    case keychainError
    case challengeTimeout
    case authTimeout
    case serverRejectedAuth
    case pairingDenied
    case socketError(String)
    case maxRetriesExceeded
}

public enum OpenClawConnectionPhase: Int, Comparable {
    case idle = 0
    case discovering = 1
    case gatewaySelected = 2
    case resolvingAuthentication = 3
    case pairing = 4
    case connecting = 5
    case socketConnected = 6
    case waitingForChallenge = 7
    case challenged = 8
    case authenticating = 9
    case authenticated = 10
    case ready = 11

    public static func < (lhs: OpenClawConnectionPhase, rhs: OpenClawConnectionPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum OpenClawConnectionState: Equatable {
    case idle
    case discovering
    case gatewaySelected
    case resolvingAuthentication
    case pairing
    case connecting
    case socketConnected
    case waitingForChallenge
    case challenged
    case authenticating
    case authenticated
    case ready
    case disconnecting
    case disconnected
    case failed(OpenClawFailureReason)

    var phase: OpenClawConnectionPhase {
        switch self {
        case .idle: return .idle
        case .discovering: return .discovering
        case .gatewaySelected: return .gatewaySelected
        case .resolvingAuthentication: return .resolvingAuthentication
        case .pairing: return .pairing
        case .connecting: return .connecting
        case .socketConnected: return .socketConnected
        case .waitingForChallenge: return .waitingForChallenge
        case .challenged: return .challenged
        case .authenticating: return .authenticating
        case .authenticated: return .authenticated
        case .ready: return .ready
        case .disconnecting: return .idle
        case .disconnected: return .idle
        case .failed: return .idle
        }
    }
}

actor OpenClawGatewayConnection: NSObject, URLSessionWebSocketDelegate {
    private let url: URL
    private let deviceID: String
    private var socket: URLSessionWebSocketTask?
    private var session: URLSession?

    // Send queue — populated when socket not yet physically open
    private var pendingOutboundQueue: [String] = []

    // Physical socket state — distinct from connectionState enum
    // Only set true in didOpen delegate, false in didClose / error
    private var isSocketPhysicallyOpen: Bool = false

    // Server-issued nonce — bound to current session only
    // NEVER generate locally. Cleared on disconnect.
    private var currentNonce: String? = nil

    // Connection identifier for logging
    private var connectionID: String? = nil

    private var connectionState: OpenClawConnectionState = .idle
    private var stateStreamContinuations: [UUID: AsyncStream<OpenClawConnectionState>.Continuation] = [:]

    nonisolated var stateStream: AsyncStream<OpenClawConnectionState> {
        AsyncStream { continuation in
            let id = UUID()
            Task {
                await self.registerStateContinuation(continuation, id: id)
            }
        }
    }

    private func registerStateContinuation(_ continuation: AsyncStream<OpenClawConnectionState>.Continuation, id: UUID) {
        self.stateStreamContinuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeStateContinuation(id: id)
            }
        }
        continuation.yield(connectionState)
    }

    private func removeStateContinuation(id: UUID) {
        self.stateStreamContinuations.removeValue(forKey: id)
    }

    private var pendingRequests: [String: CheckedContinuation<AnyCodable, Error>] = [:]

    // External long-lived stream
    private var externalEventStreamContinuation: AsyncStream<OpenClawEvent>.Continuation?

    private var handshakeContinuation: CheckedContinuation<Void, Error>?
    private var connectionOpenedContinuation: CheckedContinuation<Void, Error>?

    private var socketOpenTimeoutTask: Task<Void, Never>?
    private var discoveryTimeoutTask: Task<Void, Never>?
    private var challengeTimeoutTask: Task<Void, Never>?
    private var authTimeoutTask: Task<Void, Never>?

    private let clock = ContinuousClock()
    private var phaseStartTime: ContinuousClock.Instant?

    private var heartbeatTimer: Task<Void, Never>?
    private var reconnectionTask: Task<Void, Never>?
    private var connectionAttempt: Int = 0
    private var isManuallyDisconnected: Bool = false

    private var currentConnectionTask: Task<Void, Error>?
    private var cachedToken: String?

    init(url: URL, deviceID: String) {
        self.url = url
        self.deviceID = deviceID
        super.init()
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    private func updateState(_ newState: OpenClawConnectionState) {
        guard canTransition(from: connectionState, to: newState) else {
            logger.error("Illegal state transition: \(String(describing: self.connectionState)) -> \(String(describing: newState))")
            return
        }
        let oldState = connectionState
        connectionState = newState
        for continuation in stateStreamContinuations.values {
            continuation.yield(newState)
        }
        logger.debug("\(String(describing: oldState)) → \(String(describing: newState))")
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .gateway,
            title: "State Transition",
            description: "\(oldState) → \(newState)",
            connectionID: connectionID,
            attemptNumber: connectionAttempt
        )
    }

    private func canTransition(from: OpenClawConnectionState, to: OpenClawConnectionState) -> Bool {
        if case .failed = to { return true }
        if to == .disconnecting || to == .disconnected { return true }
        if case .failed = from, to == .idle { return true }

        switch (from, to) {
        case (.idle, .discovering), (.idle, .connecting), (.idle, .resolvingAuthentication): return true
        case (.discovering, .gatewaySelected), (.discovering, .idle): return true
        case (.gatewaySelected, .resolvingAuthentication), (.gatewaySelected, .idle): return true
        case (.resolvingAuthentication, .pairing), (.resolvingAuthentication, .connecting), (.resolvingAuthentication, .idle): return true
        case (.pairing, .connecting), (.pairing, .idle), (.pairing, .challenged), (.pairing, .authenticating): return true
        case (.connecting, .socketConnected): return true
        case (.socketConnected, .waitingForChallenge): return true
        case (.waitingForChallenge, .challenged), (.waitingForChallenge, .pairing): return true
        case (.challenged, .authenticated), (.challenged, .authenticating): return true
        case (.authenticating, .authenticated), (.authenticating, .failed): return true
        case (.authenticated, .ready): return true
        case (.ready, .idle): return true
        case (.disconnecting, .disconnected): return true
        case (.disconnected, .idle): return true
        case (.failed, .discovering), (.failed, .connecting): return true
        default: return false
        }
    }

    func getState() -> OpenClawConnectionState { connectionState }

    func connect() async throws -> AsyncStream<OpenClawEvent> {
        // Ensure clean slate
        await cleanupForNewConnection()

        isManuallyDisconnected = false
        connectionAttempt = 0

        // Create the external stream
        let (stream, continuation) = AsyncStream.makeStream(of: OpenClawEvent.self)
        self.externalEventStreamContinuation = continuation

        let task = Task {
            try await performConnect()
        }
        currentConnectionTask = task

        // We return the stream immediately so caller can observe discovery/connecting/pairing states
        return stream
    }

    private func cleanupForNewConnection() async {
        currentConnectionTask?.cancel()
        currentConnectionTask = nil

        heartbeatTimer?.cancel()
        reconnectionTask?.cancel()
        socketOpenTimeoutTask?.cancel()
        discoveryTimeoutTask?.cancel()
        challengeTimeoutTask?.cancel()
        authTimeoutTask?.cancel()

        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        isSocketPhysicallyOpen = false
        currentNonce = nil
        connectionID = nil
        pendingOutboundQueue.removeAll()

        cleanupHandshake(error: OpenClawError.connectionFailed("New connection initiated"))
        cleanupAllPendingRequests(error: OpenClawError.connectionFailed("New connection initiated"))

        connectionOpenedContinuation?.resume(throwing: OpenClawError.connectionFailed("New connection initiated"))
        connectionOpenedContinuation = nil

        connectionState = .idle
    }

    private func performConnect() async throws {
        guard let session = session else {
             throw OpenClawError.connectionFailed("Session not initialized")
        }

        connectionID = String(UUID().uuidString.prefix(8))

        let urlString = self.url.absoluteString
        Logger.ws.info("[connect] Initiating — url: \(urlString)")
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .gateway,
            title: "Connection Initiated",
            description: "Target: \(urlString)",
            connectionID: connectionID,
            attemptNumber: connectionAttempt
        )

        // PHASE: Resolve Authentication
        updateState(.resolvingAuthentication)
        cachedToken = OpenClawSecureStore.shared.getToken(for: deviceID)

        // PHASE: Connecting (Socket)
        updateState(.connecting)
        logger.info("Connecting to host: \(self.url.host ?? "unknown"), port: \(self.url.port ?? 0)")

        socket = session.webSocketTask(with: url)
        guard let socket = socket else {
            OpenClawLoggerService.shared.log(
                level: .error,
                category: .websocket,
                title: "Socket Creation Failed",
                description: "Failed to create URLSessionWebSocketTask",
                connectionID: connectionID,
                attemptNumber: connectionAttempt
            )
            throw OpenClawError.connectionFailed("Failed to create socket")
        }

        // Set continuation before resume to avoid race condition
        startSocketOpenTimeout()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.connectionOpenedContinuation = continuation
            socket.resume()
            OpenClawLoggerService.shared.log(
                level: .debug,
                category: .websocket,
                title: "WebSocket Resume",
                description: "Waiting for physical connection...",
                connectionID: connectionID,
                attemptNumber: connectionAttempt
            )
        }
        cancelSocketOpenTimeout()

        OpenClawLoggerService.shared.log(
            level: .info,
            category: .websocket,
            title: "WebSocket Connected",
            description: "Physical transport established",
            connectionID: connectionID,
            attemptNumber: connectionAttempt
        )
        updateState(.socketConnected)
        updateState(.waitingForChallenge)
        startChallengeTimeout()
        listen()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.handshakeContinuation = continuation

            // The OpenClaw gateway initiates the application handshake by sending
            // connect.challenge after the WebSocket transport is open. Do not send a
            // JSON-RPC "connect" frame here: strict gateways treat any unexpected
            // first client frame as an invalid handshake message and close with 1008.
            OpenClawLoggerService.shared.log(
                level: .info,
                category: .handshake,
                title: "Waiting for Challenge",
                description: "Transport open, expecting connect.challenge from gateway",
                connectionID: connectionID,
                attemptNumber: connectionAttempt
            )
        }
    }

    private func completeHandshake() {
        OpenClawLoggerService.shared.log(
            level: .info,
            category: .handshake,
            title: "Handshake Successful",
            description: "Connection fully established and authenticated",
            connectionID: connectionID,
            attemptNumber: connectionAttempt
        )
        logger.info("Handshake successful. Connected to \(self.url.absoluteString)")
        updateState(.authenticated)
        updateState(.ready)
        connectionAttempt = 0
        startHeartbeat()
    }

    // MARK: - URLSessionWebSocketDelegate

    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task {
            await handleSocketOpen()
        }
    }

    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task {
            await handleSocketClose(closeCode: closeCode, reason: reason)
        }
    }

    private func handleSocketOpen() {
        logger.info("Socket open success. State: \(String(describing: self.connectionState))")
        Logger.ws.info("[didOpen] Socket physically open — flushing queue")
        OpenClawLoggerService.shared.log(
            level: .debug,
            category: .websocket,
            title: "didOpen",
            description: "Delegate callback: Socket physically open",
            connectionID: connectionID,
            attemptNumber: connectionAttempt
        )
        cancelSocketOpenTimeout()
        isSocketPhysicallyOpen = true
        connectionOpenedContinuation?.resume()
        connectionOpenedContinuation = nil
        Task {
            await flushPendingQueue()
        }
    }

    private func handleSocketClose(closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) async {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "none"

        switch closeCode {
        case .normalClosure:       // 1000
            Logger.ws.warning("[didClose] Code 1000 (normal) — reason: \(reasonString)")
        case .policyViolation:     // 1008
            Logger.ws.error("[didClose] Code 1008 (policy violation) — handshake rejected by server. reason: \(reasonString)")
        default:
            Logger.ws.error("[didClose] Code \(closeCode.rawValue) — reason: \(reasonString)")
        }

        OpenClawLoggerService.shared.log(
            level: closeCode == .normalClosure ? .info : .warning,
            category: .websocket,
            title: "Socket Closed",
            description: "Code: \(closeCode.rawValue), Reason: \(reasonString)",
            connectionID: connectionID,
            attemptNumber: connectionAttempt
        )

        isSocketPhysicallyOpen = false
        currentNonce = nil
        pendingOutboundQueue.removeAll()
        updateState(.disconnected)

        logger.info("Socket closed. Code: \(closeCode.rawValue), reason: \(reasonString), state: \(String(describing: self.connectionState))")
        guard !isManuallyDisconnected else { return }
        await handleConnectionFailure(OpenClawError.connectionFailed("WebSocket closed with code \(closeCode.rawValue)"))
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task {
            await handleTaskCompletion(error: error)
        }
    }

    private func handleTaskCompletion(error: Error?) async {
        if let error = error {
            cancelSocketOpenTimeout()
            connectionOpenedContinuation?.resume(throwing: error)
            connectionOpenedContinuation = nil
            await handleConnectionFailure(error)
        }
    }

    func disconnect() {
        isManuallyDisconnected = true
        heartbeatTimer?.cancel()
        reconnectionTask?.cancel()
        socketOpenTimeoutTask?.cancel()
        challengeTimeoutTask?.cancel()
        authTimeoutTask?.cancel()
        socket?.cancel(with: .normalClosure, reason: nil)
        isSocketPhysicallyOpen = false
        currentNonce = nil
        pendingOutboundQueue.removeAll()
        updateState(.idle)
        for continuation in stateStreamContinuations.values {
            continuation.finish()
        }
        stateStreamContinuations.removeAll()
        externalEventStreamContinuation?.finish()
        cleanupHandshake(error: OpenClawError.connectionFailed("Disconnected"))
        cleanupAllPendingRequests(error: OpenClawError.connectionFailed("Disconnected"))

        connectionOpenedContinuation?.resume(throwing: OpenClawError.connectionFailed("Disconnected"))
        connectionOpenedContinuation = nil
    }

    private func startSocketOpenTimeout() {
        phaseStartTime = clock.now
        socketOpenTimeoutTask?.cancel()
        socketOpenTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10), tolerance: .seconds(0.5))
            guard !Task.isCancelled else { return }
            await self?.handleSocketOpenTimeout()
        }
    }

    private func handleSocketOpenTimeout() {
        let elapsed = phaseStartTime.map { clock.now - $0 } ?? .seconds(0)
        let elapsedMs = Int(elapsed.components.attoseconds / 1_000_000_000_000_000) + Int(elapsed.components.seconds * 1000)
        logger.error("Socket open timeout. State at fire: \(String(describing: self.connectionState)), elapsed: \(elapsedMs)ms")
        OpenClawLoggerService.shared.log(
            level: .error,
            category: .websocket,
            title: "Connection Timeout",
            description: "Socket failed to open within 10s (\(elapsedMs)ms)",
            connectionID: connectionID,
            attemptNumber: connectionAttempt
        )
        connectionOpenedContinuation?.resume(throwing: OpenClawError.connectionTimeout)
        connectionOpenedContinuation = nil
        socket?.cancel(with: .abnormalClosure, reason: nil)
        updateState(.failed(.socketError("open_timeout")))
    }

    private func cancelSocketOpenTimeout() {
        socketOpenTimeoutTask?.cancel()
        socketOpenTimeoutTask = nil
    }

    private func startChallengeTimeout() {
        phaseStartTime = clock.now
        challengeTimeoutTask?.cancel()
        challengeTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8), tolerance: .seconds(0.5))
            guard !Task.isCancelled else { return }
            await self?.handleChallengeTimeout()
        }
    }

    private func handleChallengeTimeout() {
        let elapsed = phaseStartTime.map { clock.now - $0 } ?? .seconds(0)
        let elapsedMs = Int(elapsed.components.attoseconds / 1_000_000_000_000_000) + Int(elapsed.components.seconds * 1000)
        logger.error("Challenge timeout. State at fire: \(String(describing: self.connectionState)), elapsed: \(elapsedMs)ms")
        OpenClawLoggerService.shared.log(
            level: .error,
            category: .handshake,
            title: "Challenge Timeout",
            description: "Gateway did not send connect.challenge within 8s (\(elapsedMs)ms)",
            connectionID: connectionID,
            attemptNumber: connectionAttempt
        )
        cleanupHandshake(error: OpenClawError.connectionTimeout)
        socket?.cancel(with: .abnormalClosure, reason: nil)
        updateState(.failed(.challengeTimeout))
    }

    private func cancelChallengeTimeout() {
        challengeTimeoutTask?.cancel()
        challengeTimeoutTask = nil
    }

    private func startAuthTimeout() {
        phaseStartTime = clock.now
        authTimeoutTask?.cancel()
        authTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5), tolerance: .seconds(0.5))
            guard !Task.isCancelled else { return }
            await self?.handleAuthTimeout()
        }
    }

    private func handleAuthTimeout() {
        let elapsed = phaseStartTime.map { clock.now - $0 } ?? .seconds(0)
        let elapsedMs = Int(elapsed.components.attoseconds / 1_000_000_000_000_000) + Int(elapsed.components.seconds * 1000)
        logger.error("Auth timeout. State at fire: \(String(describing: self.connectionState)), elapsed: \(elapsedMs)ms")
        OpenClawLoggerService.shared.log(
            level: .error,
            category: .authentication,
            title: "Authentication Timeout",
            description: "Server did not acknowledge connect.response within 5s (\(elapsedMs)ms)",
            connectionID: connectionID,
            attemptNumber: connectionAttempt
        )
        cleanupHandshake(error: OpenClawError.authTimeoutWithoutServerAck)
        socket?.cancel(with: .abnormalClosure, reason: nil)
        updateState(.failed(.authTimeout))
    }

    private func cancelAuthTimeout() {
        authTimeoutTask?.cancel()
        authTimeoutTask = nil
    }

    private func cleanupHandshake(error: Error) {
        if let continuation = handshakeContinuation {
            continuation.resume(throwing: error)
            handshakeContinuation = nil
        }
    }

    private func cleanupAllPendingRequests(error: Error) {
        for continuation in pendingRequests.values {
            continuation.resume(throwing: error)
        }
        pendingRequests.removeAll()
    }

    func sendRequest(_ method: String, params: [String: AnyCodable] = [:]) async throws -> AnyCodable {
        guard connectionState == .ready || connectionState == .authenticated || connectionState == .pairing || connectionState == .authenticating else {
            throw OpenClawError.connectionFailed("Not connected")
        }
        return try await sendRequestInternal(method, params: params)
    }

    func send(message: String) async {
        let currentState = connectionState

        // Allow handshake-critical messages even before fully ready
        let isHandshakeMessage = message.contains("\"method\":\"pair\"") || message.contains("\"event\":\"connect.response\"")

        guard currentState == .authenticated || currentState == .ready || (isHandshakeMessage && isSocketPhysicallyOpen) else {
            pendingOutboundQueue.append(message)
            let count = pendingOutboundQueue.count
            Logger.ws.warning("[send] Queued (state=\(String(describing: currentState)), depth=\(count), isHandshake=\(isHandshakeMessage))")
            return
        }
        await transmit(message)
    }

    private func transmit(_ message: String) async {
        guard isSocketPhysicallyOpen, let socket = socket else {
            pendingOutboundQueue.append(message)
            let count = pendingOutboundQueue.count
            Logger.ws.warning("[transmit] Queued — isSocketPhysicallyOpen=false. depth=\(count)")
            return
        }

        do {
            let currentState = connectionState
            Logger.ws.debug("[transmit] SEND → \(message)")
            Logger.ws.debug("[transmit] State at send: \(String(describing: currentState))")

            OpenClawLoggerService.shared.log(
                level: .debug,
                category: .websocket,
                title: "Frame Outbound",
                description: "Sending \(message.count) bytes",
                connectionID: connectionID,
                attemptNumber: connectionAttempt,
                payload: message
            )

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                socket.send(.string(message)) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            Logger.ws.error("[transmit] Send failed: \(error.localizedDescription)")
            await handleConnectionFailure(error)
        }
    }

    private func flushPendingQueue() async {
        guard isSocketPhysicallyOpen, !pendingOutboundQueue.isEmpty else { return }
        let count = pendingOutboundQueue.count
        Logger.ws.info("[flushPendingQueue] Flushing \(count) queued message(s)")
        let snapshot = pendingOutboundQueue
        pendingOutboundQueue.removeAll()
        for message in snapshot {
            await transmit(message)
        }
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
                let text = String(data: data, encoding: .utf8) ?? "<binary data>"
                OpenClawLoggerService.shared.log(
                    level: .debug,
                    category: .websocket,
                    title: "Frame Inbound (Data)",
                    description: "Received \(data.count) bytes",
                    connectionID: connectionID,
                    attemptNumber: connectionAttempt,
                    payload: text
                )
                await handleIncomingData(data)
            case .string(let text):
                OpenClawLoggerService.shared.log(
                    level: .debug,
                    category: .websocket,
                    title: "Frame Inbound (String)",
                    description: "Received \(text.count) characters",
                    connectionID: connectionID,
                    attemptNumber: connectionAttempt,
                    payload: text
                )
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
        OpenClawLoggerService.shared.log(
            level: .error,
            category: .network,
            title: "Connection Failure",
            description: errorMsg,
            connectionID: connectionID,
            attemptNumber: connectionAttempt,
            error: error
        )

        // Categorize error and decide if we should fail or reconnect
        let isTerminal: Bool
        if let clawError = error as? OpenClawError {
            switch clawError {
            case .invalidAuthMethodReuse, .missingChallengeNonce, .protocolMismatchDetected(_):
                isTerminal = true
            default:
                isTerminal = false
            }
        } else {
            isTerminal = false
        }

        if isTerminal {
             updateState(.failed(.socketError(errorMsg)))
        } else {
             updateState(.failed(.socketError(errorMsg)))
             scheduleReconnection()
        }

        cleanupHandshake(error: error)
        cleanupAllPendingRequests(error: error)
    }

    private func scheduleReconnection() {
        reconnectionTask?.cancel()

        // Terminal errors that should stop reconnection
        if case .failed(let reason) = connectionState {
            switch reason {
            case .missingToken, .emptyToken, .invalidToken, .serverRejectedAuth, .pairingDenied:
                logger.info("Terminal failure reason: \(String(describing: reason)). Stopping reconnection.")
                return
            default:
                break
            }
        }

        reconnectionTask = Task { [weak self] in
            guard let self = self else { return }

            let connectionID = await self.connectionID

            let attempt = await getAttempt()
            if attempt >= 5 {
                logger.error("Max retries exceeded. Total attempts: \(attempt)")
                await self.updateState(.failed(.maxRetriesExceeded))
                return
            }

            let delay = min(pow(2.0, Double(attempt)), 16.0)
            logger.info("Scheduling reconnect attempt \(attempt + 1) in \(delay)s")
            OpenClawLoggerService.shared.log(
                level: .info,
                category: .gateway,
                title: "Scheduling Reconnection",
                description: "Attempt \(attempt + 1) in \(Int(delay))s",
                connectionID: connectionID,
                attemptNumber: attempt
            )
            await updateState(.connecting)

            await cancelSocketOpenTimeout()
            await cancelChallengeTimeout()
            await cancelAuthTimeout()

            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            let manuallyDisconnected = await self.getIsManuallyDisconnected()
            if !Task.isCancelled && !manuallyDisconnected {
                await self.incrementAttempt()
                do {
                    _ = try await self.performConnect()
                } catch {
                    logger.error("Reconnection attempt \(attempt + 1) failed: \(error.localizedDescription)")
                    // performConnect failure will trigger handleConnectionFailure -> scheduleReconnection again
                }
            }
        }
    }

    private func getAttempt() -> Int { connectionAttempt }
    private func incrementAttempt() { connectionAttempt += 1 }
    private func getIsManuallyDisconnected() -> Bool { isManuallyDisconnected }

    private func handleIncomingData(_ data: Data) async {
        let rawString = String(data: data, encoding: .utf8) ?? ""

        // Handshake routing
        if rawString.contains("\"event\":\"connect.challenge\"") {
            cancelChallengeTimeout()
            await handleChallenge(rawString)
            return
        }

        // Standard JSON-RPC and Event processing
        if let response = try? JSONDecoder().decode(OpenClawRPCResponse.self, from: data), let id = response.id {
            // First non-handshake message or ANY message during authenticating state advances state
            if connectionState == .challenged || connectionState == .authenticating {
                cancelAuthTimeout()
                handshakeContinuation?.resume()
                handshakeContinuation = nil
                completeHandshake()
                await flushPendingQueue()
            }

            do {
                try response.validate()
            } catch {
                OpenClawLoggerService.shared.log(
                    level: .error,
                    category: .handshake,
                    title: "Response Validation Failed",
                    description: error.localizedDescription,
                    connectionID: connectionID,
                    attemptNumber: connectionAttempt,
                    error: error
                )
            }

            if let continuation = pendingRequests.removeValue(forKey: id) {
                if let error = response.error {
                    continuation.resume(throwing: OpenClawError.protocolError(error.message))
                } else if let result = response.result {
                    // Extract token if present in connect response
                    if let dict = result.value as? [String: Any], let token = dict["token"] as? String {
                        OpenClawSecureStore.shared.saveToken(token, for: deviceID)
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
            // First non-handshake message or ANY message during authenticating state advances state
            if connectionState == .challenged || connectionState == .authenticating {
                cancelAuthTimeout()
                handshakeContinuation?.resume()
                handshakeContinuation = nil
                completeHandshake()
                await flushPendingQueue()
            }

            externalEventStreamContinuation?.yield(event)
            return
        }
    }

    func pair() async throws {
        guard connectionState == .pairing else {
            throw OpenClawError.protocolError("Not in pairing state")
        }

        OpenClawLoggerService.shared.log(
            level: .info,
            category: .pairing,
            title: "Pairing Started",
            description: "Sending pairing request to gateway",
            connectionID: connectionID,
            attemptNumber: connectionAttempt
        )

        let params: [String: AnyCodable] = [
            "device_id": AnyCodable(deviceID),
            "device_name": AnyCodable(UIDevice.current.name)
        ]

        do {
            let result = try await sendRequestInternal("pair", params: params)
            OpenClawLoggerService.shared.log(
                level: .info,
                category: .pairing,
                title: "Pairing Approved",
                description: "Gateway accepted pairing request",
                connectionID: connectionID,
                attemptNumber: connectionAttempt
            )
            if let dict = result.value as? [String: Any], let token = dict["token"] as? String {
                self.cachedToken = token
                OpenClawSecureStore.shared.saveToken(token, for: deviceID)
                OpenClawLoggerService.shared.log(
                    level: .debug,
                    category: .pairing,
                    title: "Token Persisted",
                    description: "New auth token saved to Keychain",
                    connectionID: connectionID,
                    attemptNumber: connectionAttempt
                )
            }

            // After successful pairing, immediately attempt handshake response with the new token
            if let nonce = self.currentNonce {
                updateState(.authenticating)
                startAuthTimeout()
                await sendHandshakeResponse(nonce: nonce, signature: self.cachedToken ?? "")
            } else {
                // If we don't have a nonce, we might need to wait for one or restart
                logger.warning("No nonce available after pairing, restarting connection")
                disconnect()
                _ = try await performConnect()
            }
        } catch {
            OpenClawLoggerService.shared.log(
                level: .error,
                category: .pairing,
                title: "Pairing Failed",
                description: error.localizedDescription,
                connectionID: connectionID,
                attemptNumber: connectionAttempt,
                error: error
            )
            updateState(.failed(.pairingDenied))
            throw error
        }
    }

    private func handleChallenge(_ rawMessage: String) async {
        Logger.ws.debug("[handleChallenge] Raw challenge: \(rawMessage)")

        guard let data = rawMessage.data(using: .utf8) else {
            Logger.ws.error("[handleChallenge] Failed to encode challenge string to UTF-8 data")
            return
        }

        do {
            let challenge = try JSONDecoder().decode(OpenClawChallengeMessage.self, from: data)
            let nonce = challenge.payload.nonce
            Logger.ws.info("[handleChallenge] Nonce extracted: \(nonce)")

            // Bind nonce to current session
            currentNonce = nonce

            OpenClawLoggerService.shared.log(
                level: .info,
                category: .handshake,
                title: "connect.challenge Received",
                description: "Nonce: \(nonce)",
                connectionID: connectionID,
                attemptNumber: connectionAttempt,
                payload: rawMessage
            )

            // Advance state
            updateState(.challenged)

            // Fetch signature (token) from SecureStore
            guard let signature = cachedToken ?? OpenClawSecureStore.shared.getToken(for: deviceID) else {
                Logger.ws.error("[handleChallenge] No auth token in Keychain — cannot complete handshake")
                OpenClawLoggerService.shared.log(
                    level: .warning,
                    category: .authentication,
                    title: "Token Missing",
                    description: "No stored token found for this device. Pairing required.",
                    connectionID: connectionID,
                    attemptNumber: connectionAttempt
                )
                cancelAuthTimeout()
                updateState(.pairing)
                return
            }
            cachedToken = signature

            // Send response immediately
            updateState(.authenticating)
            startAuthTimeout()
            await sendHandshakeResponse(nonce: nonce, signature: signature)

        } catch {
            Logger.ws.error("[handleChallenge] JSON decode failed: \(error.localizedDescription)")
            Logger.ws.error("[handleChallenge] Raw payload was: \(rawMessage)")
        }
    }

    private func sendHandshakeResponse(nonce: String, signature: String) async {
        let response = OpenClawResponseMessage(
            payload: .init(nonce: nonce, signature: signature)
        )

        do {
            let encoded = try JSONEncoder().encode(response)
            guard let jsonString = String(data: encoded, encoding: .utf8) else {
                Logger.ws.error("[sendHandshakeResponse] Failed to encode response to UTF-8 string")
                return
            }

            let currentState = connectionState
            Logger.ws.info("[sendHandshakeResponse] Sending connect.response: \(jsonString)")
            Logger.ws.debug("[sendHandshakeResponse] State at send: \(String(describing: currentState))")

            OpenClawLoggerService.shared.log(
                level: .info,
                category: .handshake,
                title: "Sending connect.response",
                description: "Responding to challenge with signed nonce",
                connectionID: connectionID,
                attemptNumber: connectionAttempt,
                payload: jsonString
            )

            // Direct transmit
            await transmit(jsonString)

        } catch {
            Logger.ws.error("[sendHandshakeResponse] JSON encoding failed: \(error.localizedDescription)")
        }
    }

    private var socketStateDescription: String {
        "open=\(isSocketPhysicallyOpen), task=\(socket == nil ? "nil" : "present"), connection=\(connectionState)"
    }


    private func sendRequestInternal(_ method: String, params: [String: AnyCodable]) async throws -> AnyCodable {
        let request = OpenClawRPCRequest(method: method, params: params)

        do {
            try request.validate()
        } catch {
            OpenClawLoggerService.shared.log(
                level: .error,
                category: .gateway,
                title: "RPC Validation Failed",
                description: "Method: \(method)",
                connectionID: connectionID,
                attemptNumber: connectionAttempt,
                error: error
            )
            throw error
        }

        let data = try JSONEncoder().encode(request)
        let text = String(data: data, encoding: .utf8) ?? "{}"

        OpenClawLoggerService.shared.log(
            level: .debug,
            category: .gateway,
            title: "RPC Outbound",
            description: "Method: \(method), ID: \(request.id)",
            connectionID: connectionID,
            attemptNumber: connectionAttempt,
            payload: text
        )

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[request.id] = continuation

            // OpenClaw Gateway requires text frames
            Task { [weak self] in
                await self?.send(message: text)
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
            OpenClawLoggerService.shared.log(
                level: .error,
                category: .gateway,
                title: "RPC Timeout",
                description: "Request ID: \(id)",
                connectionID: connectionID,
                attemptNumber: connectionAttempt
            )
            logger.error("RPC request timed out: \(id)")
            continuation.resume(throwing: OpenClawError.requestTimeout)
        }
    }

    private func startHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30s
                guard let self = self else { break }
                if await self.getState() == .ready {
                    _ = try? await self.sendRequest("ping")
                } else {
                    break
                }
            }
        }
    }
}
