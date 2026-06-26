import Foundation
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.toolskit.openclaw", category: "handshake")

enum OpenClawFailureReason: Equatable {
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

enum ConnectionPhase: Int, Comparable {
    case idle = 0
    case discovering = 1
    case gatewaySelected = 2
    case resolvingAuthentication = 3
    case pairing = 4
    case connecting = 5
    case socketConnected = 6
    case waitingForChallenge = 7
    case authenticating = 8
    case authenticated = 9
    case ready = 10

    static func < (lhs: ConnectionPhase, rhs: ConnectionPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum ConnectionState: Equatable {
    case idle
    case discovering
    case gatewaySelected
    case resolvingAuthentication
    case pairing
    case connecting
    case socketConnected
    case waitingForChallenge
    case authenticating
    case authenticated
    case ready
    case disconnecting
    case disconnected
    case failed(OpenClawFailureReason)

    var phase: ConnectionPhase {
        switch self {
        case .idle: return .idle
        case .discovering: return .discovering
        case .gatewaySelected: return .gatewaySelected
        case .resolvingAuthentication: return .resolvingAuthentication
        case .pairing: return .pairing
        case .connecting: return .connecting
        case .socketConnected: return .socketConnected
        case .waitingForChallenge: return .waitingForChallenge
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

    private var _state: ConnectionState = .idle
    private var stateStreamContinuations: [UUID: AsyncStream<ConnectionState>.Continuation] = [:]

    nonisolated var stateStream: AsyncStream<ConnectionState> {
        AsyncStream { continuation in
            let id = UUID()
            Task {
                await self.registerStateContinuation(continuation, id: id)
            }
        }
    }

    private func registerStateContinuation(_ continuation: AsyncStream<ConnectionState>.Continuation, id: UUID) {
        self.stateStreamContinuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeStateContinuation(id: id)
            }
        }
        continuation.yield(_state)
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

    private var authNonce: String?
    private var authTimestamp: Int?

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

    private func updateState(_ newState: ConnectionState) {
        guard canTransition(from: _state, to: newState) else {
            logger.error("Illegal state transition: \(String(describing: self._state)) -> \(String(describing: newState))")
            return
        }
        let oldState = _state
        _state = newState
        for continuation in stateStreamContinuations.values {
            continuation.yield(newState)
        }
        logger.debug("\(String(describing: oldState)) → \(String(describing: newState))")
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("STATE: \(newState)", type: .info)
        }
    }

    private func canTransition(from: ConnectionState, to: ConnectionState) -> Bool {
        if case .failed = to { return true }
        if case .failed = from, to == .idle { return true }

        switch (from, to) {
        case (.idle, .discovering), (.idle, .connecting), (.idle, .resolvingAuthentication): return true
        case (.discovering, .gatewaySelected), (.discovering, .idle): return true
        case (.gatewaySelected, .resolvingAuthentication), (.gatewaySelected, .idle): return true
        case (.resolvingAuthentication, .pairing), (.resolvingAuthentication, .connecting), (.resolvingAuthentication, .idle): return true
        case (.pairing, .connecting), (.pairing, .idle): return true
        case (.connecting, .socketConnected), (.connecting, .disconnecting): return true
        case (.socketConnected, .waitingForChallenge), (.socketConnected, .disconnecting): return true
        case (.waitingForChallenge, .authenticating), (.waitingForChallenge, .disconnecting): return true
        case (.authenticating, .authenticated), (.authenticating, .disconnecting): return true
        case (.authenticated, .ready), (.authenticated, .disconnecting): return true
        case (.ready, .disconnecting): return true
        case (.disconnecting, .disconnected): return true
        case (.disconnected, .idle): return true
        case (.failed, .discovering), (.failed, .connecting): return true
        default: return false
        }
    }

    func getState() -> ConnectionState { _state }

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

        cleanupHandshake(error: OpenClawError.connectionFailed("New connection initiated"))
        cleanupAllPendingRequests(error: OpenClawError.connectionFailed("New connection initiated"))

        connectionOpenedContinuation?.resume(throwing: OpenClawError.connectionFailed("New connection initiated"))
        connectionOpenedContinuation = nil

        _state = .idle
    }

    private func performConnect() async throws {
        guard let session = session else {
             throw OpenClawError.connectionFailed("Session not initialized")
        }

        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Initiating connection to \(url.absoluteString)", type: .network)
        }

        // PHASE: Resolve Authentication
        updateState(.resolvingAuthentication)
        cachedToken = OpenClawSecureStore.shared.getToken(for: deviceID)

        // PHASE: Connecting (Socket)
        updateState(.connecting)
        logger.info("Connecting to host: \(self.url.host ?? "unknown"), port: \(self.url.port ?? 0)")

        socket = session.webSocketTask(with: url)
        guard let socket = socket else {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Failed to create URLSessionWebSocketTask", type: .error)
            }
            throw OpenClawError.connectionFailed("Failed to create socket")
        }

        // Set continuation before resume to avoid race condition
        startSocketOpenTimeout()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.connectionOpenedContinuation = continuation
            socket.resume()
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("WebSocket resume() called, waiting for open...", type: .network)
            }
        }
        cancelSocketOpenTimeout()

        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("WebSocket opened successfully", type: .network)
        }
        updateState(.socketConnected)
        listen()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.handshakeContinuation = continuation

            // OpenClaw Protocol: The first client frame must be a 'connect' request.
            Task {
                do {
                    Task { @MainActor in
                        OpenClawDiagnosticsManager.shared.log("Sending initial 'connect' request", type: .protocolMsg)
                    }
                    updateState(.waitingForChallenge)
                    startChallengeTimeout()
                    _ = try await self.sendRequestInternal("connect", params: [:])
                } catch {
                    Task { @MainActor in
                        OpenClawDiagnosticsManager.shared.log("Initial 'connect' request failed: \(error.localizedDescription)", type: .error)
                    }
                    self.cleanupHandshake(error: error)
                }
            }
        }
    }

    private func completeHandshake() {
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Handshake successful, connection established", type: .info)
        }
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

    private func handleSocketOpen() {
        logger.info("Socket open success. State: \(String(describing: self._state))")
        cancelSocketOpenTimeout()
        connectionOpenedContinuation?.resume()
        connectionOpenedContinuation = nil
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
        logger.error("Socket open timeout. State at fire: \(String(describing: self._state)), elapsed: \(elapsedMs)ms")
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Timeout reason: socket_open (\(elapsedMs)ms)", type: .error)
        }
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
        logger.error("Challenge timeout. State at fire: \(String(describing: self._state)), elapsed: \(elapsedMs)ms")
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Timeout reason: waiting_challenge (\(elapsedMs)ms)", type: .error)
        }
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
        logger.error("Auth timeout. State at fire: \(String(describing: self._state)), elapsed: \(elapsedMs)ms")
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Timeout reason: authentication (\(elapsedMs)ms)", type: .error)
        }
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
        guard _state == .ready else {
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
                    Task { @MainActor in
                        OpenClawDiagnosticsManager.shared.log("OPENCLAW INBOUND\n\(text)", type: .protocolMsg)
                    }
                }
                await handleIncomingData(data)
            case .string(let text):
                Task { @MainActor in
                    OpenClawDiagnosticsManager.shared.log("OPENCLAW INBOUND\n\(text)", type: .protocolMsg)
                }
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
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Connection failure: \(errorMsg)", type: .error)
        }

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
        if case .failed(let reason) = _state {
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

            let attempt = await getAttempt()
            if attempt >= 5 {
                logger.error("Max retries exceeded. Total attempts: \(attempt)")
                await self.updateState(.failed(.maxRetriesExceeded))
                return
            }

            let delay = min(pow(2.0, Double(attempt)), 16.0)
            logger.info("Scheduling reconnect attempt \(attempt + 1) in \(delay)s")
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Reconnect attempt \(attempt + 1) in \(Int(delay))s", type: .info)
            }
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
        // Try decoding as Response
        if let response = try? JSONDecoder().decode(OpenClawRPCResponse.self, from: data), let id = response.id {
            do {
                try response.validate()
            } catch {
                Task { @MainActor in
                    OpenClawDiagnosticsManager.shared.log("Response validation failed: \(error)", type: .error)
                }
            }

            if let continuation = pendingRequests.removeValue(forKey: id) {
                if let error = response.error {
                    if _state == .authenticating {
                        cancelAuthTimeout()
                        updateState(.failed(.serverRejectedAuth))
                    }
                    continuation.resume(throwing: OpenClawError.protocolError(error.message))
                } else if let result = response.result {
                    // Extract token if present in connect response
                    if _state == .authenticating {
                        cancelAuthTimeout()
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
                cancelChallengeTimeout()
                await respondToChallenge(event)
            }
            return
        }
    }

    func pair() async throws {
        guard _state == .pairing else {
            throw OpenClawError.protocolError("Not in pairing state")
        }

        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Pairing request sent", type: .protocolMsg)
        }

        let params: [String: AnyCodable] = [
            "device_id": AnyCodable(deviceID),
            "device_name": AnyCodable(UIDevice.current.name)
        ]

        do {
            let result = try await sendRequestInternal("pair", params: params)
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Pairing approved", type: .info)
            }
            if let dict = result.value as? [String: Any], let token = dict["token"] as? String {
                self.cachedToken = token
                OpenClawSecureStore.shared.saveToken(token, for: deviceID)
                Task { @MainActor in
                    OpenClawDiagnosticsManager.shared.log("Token stored", type: .info)
                }
            }

            // After successful pairing, immediately attempt authentication with the new token
            // instead of disconnecting.
            if let nonce = self.authNonce {
                await performAuthentication(nonce: nonce, token: self.cachedToken ?? "")
            } else {
                // If we don't have a nonce, we might need to wait for one or restart
                logger.warning("No nonce available after pairing, restarting connection")
                disconnect()
                _ = try await performConnect()
            }
        } catch {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Pairing failed: \(error.localizedDescription)", type: .error)
            }
            updateState(.failed(.pairingDenied))
            throw error
        }
    }

    private func respondToChallenge(_ event: OpenClawEvent) async {
        let currentState = _state
        guard currentState == .waitingForChallenge else {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Ignoring challenge: not in waitingForChallenge state (current: \(currentState))", type: .error)
            }
            return
        }

        guard let payload = event.payload.value as? [String: Any],
              let nonce = payload["nonce"] as? String else {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Invalid challenge payload: missing nonce", type: .error)
            }
            cleanupHandshake(error: OpenClawError.missingChallengeNonce)
            updateState(.failed(.challengeTimeout))
            return
        }

        // State Safety Check
        guard socket?.state == .running else {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Cannot send auth: socket is not running", type: .error)
            }
            cleanupHandshake(error: OpenClawError.socketClosedDuringAuth)
            updateState(.failed(.socketError("Socket closed during auth")))
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        self.authNonce = nonce
        self.authTimestamp = timestamp
        logger.debug("connect.challenge received. Nonce: \(String(nonce.prefix(8))), timestamp: \(timestamp)")

        logger.debug("Starting token resolution")
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Starting token lookup", type: .info)
        }
        let token = self.cachedToken ?? OpenClawSecureStore.shared.getToken(for: deviceID)
        self.cachedToken = token

        if token == nil || token?.isEmpty == true {
            logger.info("Token missing, pairing required")
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Token missing. Pairing required", type: .info)
            }
            updateState(.pairing)
            return
        }

        await performAuthentication(nonce: nonce, token: token!)
    }

    private func performAuthentication(nonce: String, token: String) async {
        logger.debug("Authenticating with token, length: \(token.count)")
        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("Authenticating with token", type: .info)
        }

        updateState(.authenticating)
        startAuthTimeout()

        let authParams: [String: AnyCodable] = [
            "nonce": AnyCodable(nonce),
            "token": AnyCodable(token),
            "device_id": AnyCodable(deviceID),
            "role": AnyCodable("operator"),
            "metadata": AnyCodable([
                "device_name": UIDevice.current.name,
                "client_id": "com.toolskit.openclaw"
            ])
        ]

        do {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Authentication started", type: .protocolMsg)
            }

            // Log redacted payload
            var logParams = authParams
            logParams["token"] = AnyCodable("[REDACTED]")
            let logReq = OpenClawRPCRequest(method: "authenticate", params: logParams)
            if let logData = try? JSONEncoder().encode(logReq), let logText = String(data: logData, encoding: .utf8) {
                 logger.debug("Sending authenticate RPC: \(logText)")
            }

            _ = try await sendRequestInternal("authenticate", params: authParams)

            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Authentication successful", type: .info)
            }
            cancelAuthTimeout()
            handshakeContinuation?.resume()
            handshakeContinuation = nil
            completeHandshake()
        } catch {
            cancelAuthTimeout()
            let errorMsg = error.localizedDescription
            let errorState = _state
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Authentication rejected: \(errorMsg)\nState: \(errorState)", type: .error)
            }
            let authError = OpenClawError.challengeResponseRejected(errorMsg)
            cleanupHandshake(error: authError)
            updateState(.failed(.serverRejectedAuth))
        }
    }

    private func sendRequestInternal(_ method: String, params: [String: AnyCodable]) async throws -> AnyCodable {
        let request = OpenClawRPCRequest(method: method, params: params)

        do {
            try request.validate()
        } catch {
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Request validation failed for \(method): \(error)", type: .error)
            }
            throw error
        }

        let data = try JSONEncoder().encode(request)
        let text = String(data: data, encoding: .utf8) ?? "{}"

        Task { @MainActor in
            OpenClawDiagnosticsManager.shared.log("OPENCLAW OUTBOUND\n\(text)", type: .protocolMsg)
        }

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
            Task { @MainActor in
                OpenClawDiagnosticsManager.shared.log("Request timed out: \(id)", type: .error)
            }
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
