import Foundation
import Network

/// Lightweight HTTP server for WiFi music transfer.
@MainActor
final class WiFiTransferServer: ObservableObject {
    static let shared = WiFiTransferServer()

    @Published var isRunning = false
    @Published var ipAddress: String = ""
    @Published var port: UInt16 = 8765
    @Published var pairingCode: String = ""
    @Published var transferLog: [String] = []

    private var listener: NWListener?
    private var validatedSessions: Set<String> = []

    private init() {}

    // MARK: - Start / Stop

    func start() {
        guard !isRunning else { return }
        pairingCode = generateCode()
        ipAddress = getLocalIP() ?? "—"

        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            let nwPort = NWEndpoint.Port(rawValue: port) ?? 8765
            listener = try NWListener(using: params, on: nwPort)
        } catch {
            InternalLogger.shared.log("WiFiTransferServer: failed to create listener — \(error)", level: .error)
            return
        }

        listener?.newConnectionHandler = { [weak self] connection in
            connection.start(queue: .global(qos: .userInitiated))
            Task { @MainActor [weak self] in
                self?.handleConnection(connection)
            }
        }
        listener?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isRunning = true
                    self?.appendLog("Server started on \(self?.ipAddress ?? ""):\(self?.port ?? 0)")
                case .failed(let error):
                    self?.isRunning = false
                    InternalLogger.shared.log("WiFiTransferServer: listener failed — \(error)", level: .error)
                default:
                    break
                }
            }
        }
        listener?.start(queue: .global(qos: .userInitiated))
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        validatedSessions = []
        appendLog("Server stopped.")
    }

    // MARK: - Connection Handler

    private func handleConnection(_ connection: NWConnection) {
        receiveRequest(from: connection)
    }

    private func receiveRequest(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let self, let data, !data.isEmpty else {
                connection.cancel()
                return
            }

            let raw = String(data: data, encoding: .utf8) ?? ""
            let lines = raw.components(separatedBy: "\r\n")
            let requestLine = lines.first ?? ""
            let parts = requestLine.components(separatedBy: " ")
            guard parts.count >= 2 else { connection.cancel(); return }
            let method = parts[0]
            let path = parts[1]

            switch (method, path) {
            case ("POST", "/validate-code"):
                var headerEnd = 0
                for (i, line) in lines.enumerated() where line.isEmpty {
                    headerEnd = i
                    break
                }
                let bodyStr = lines.dropFirst(headerEnd + 1).joined(separator: "\r\n")
                let body = bodyStr.data(using: .utf8) ?? Data()
                Task { @MainActor [weak self] in self?.handleValidateCode(body: body, connection: connection) }
            case ("POST", "/upload-chunk"):
                Task { @MainActor [weak self] in self?.handleUploadChunk(rawRequest: data, connection: connection) }
            case ("POST", "/finalize-upload"):
                let body = self.extractHTTPBody(from: data)
                Task { @MainActor [weak self] in self?.handleFinalizeUpload(body: body, connection: connection) }
            default:
                Task { @MainActor [weak self] in self?.sendNotFound(connection) }
            }
        }
    }

    // MARK: - Endpoint Handlers

    private func handleValidateCode(body: Data, connection: NWConnection) {
        struct CodeRequest: Decodable { let code: String }
        if let req = try? JSONDecoder().decode(CodeRequest.self, from: body),
           req.code == pairingCode {
            let sessionID = UUID().uuidString
            DispatchQueue.main.async { self.validatedSessions.insert(sessionID) }
            sendJSON("{\"success\":true,\"session\":\"\(sessionID)\"}", connection: connection, status: 200)
            appendLog("Device paired successfully.")
        } else {
            sendJSON("{\"success\":false,\"error\":\"Invalid code\"}", connection: connection, status: 401)
            InternalLogger.shared.log("WiFiTransferServer: invalid pairing code attempt", level: .warning)
        }
    }

    private func handleUploadChunk(rawRequest: Data, connection: NWConnection) {
        let session = extractHeader("X-Session", from: rawRequest)
        guard let session, validatedSessions.contains(session) else {
            sendJSON("{\"success\":false,\"error\":\"Unauthorized\"}", connection: connection, status: 401)
            InternalLogger.shared.log("WiFiTransferServer: unauthorized chunk upload", level: .warning)
            return
        }

        let filename = extractHeader("X-Filename", from: rawRequest) ?? "upload_\(Date().timeIntervalSince1970).mp3"
        let chunkIndex = Int(extractHeader("X-Chunk-Index", from: rawRequest) ?? "0") ?? 0
        let chunkData = extractHTTPBody(from: rawRequest)

        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileDir = cacheDir.appendingPathComponent("wifi_transfer").appendingPathComponent(sanitize(filename))
        try? FileManager.default.createDirectory(at: fileDir, withIntermediateDirectories: true)
        let chunkFile = fileDir.appendingPathComponent("chunk_\(chunkIndex)")

        do {
            try chunkData.write(to: chunkFile)
            sendJSON("{\"success\":true}", connection: connection, status: 200)
            appendLog("Received chunk \(chunkIndex) for '\(filename)'")
        } catch {
            sendJSON("{\"success\":false,\"error\":\"Write failed\"}", connection: connection, status: 500)
            InternalLogger.shared.log("WiFiTransferServer: chunk write failed — \(error)", level: .error)
        }
    }

    private func handleFinalizeUpload(body: Data, connection: NWConnection) {
        struct FinalizeRequest: Decodable { let session: String; let filename: String; let totalChunks: Int }
        guard let req = try? JSONDecoder().decode(FinalizeRequest.self, from: body),
              validatedSessions.contains(req.session) else {
            sendJSON("{\"success\":false,\"error\":\"Unauthorized\"}", connection: connection, status: 401)
            return
        }

        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let tempDir = cacheDir
            .appendingPathComponent("wifi_transfer")
            .appendingPathComponent(sanitize(req.filename))

        var assembled = Data()
        for i in 0..<req.totalChunks {
            let chunkFile = tempDir.appendingPathComponent("chunk_\(i)")
            if let data = try? Data(contentsOf: chunkFile) {
                assembled.append(data)
            }
        }

        guard !assembled.isEmpty else {
            sendJSON("{\"success\":false,\"error\":\"No chunks found\"}", connection: connection, status: 400)
            return
        }

        let isZIP = req.filename.lowercased().hasSuffix(".zip")
        Task { @MainActor in
            do {
                if isZIP {
                    let zipURL = cacheDir.appendingPathComponent(req.filename)
                    try assembled.write(to: zipURL)
                    defer { try? FileManager.default.removeItem(at: zipURL) }
                    if let playlist = await MusicLibraryManager.shared.importFromZIP(at: zipURL, playlistName: req.filename) {
                        self.appendLog("Imported \(playlist.songIDs.count) files from ZIP '\(req.filename)'")
                    }
                } else {
                    try await MusicLibraryManager.shared.importAudioData(assembled, filename: req.filename)
                    self.appendLog("Imported '\(req.filename)' (\(assembled.count / 1024) KB)")
                }
                self.sendJSON("{\"success\":true}", connection: connection, status: 200)
            } catch {
                self.sendJSON("{\"success\":false,\"error\":\"\(error.localizedDescription)\"}", connection: connection, status: 500)
                InternalLogger.shared.log("WiFiTransferServer: finalize failed — \(error)", level: .error)
            }
        }

        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - HTTP Helpers

    private func sendJSON(_ json: String, connection: NWConnection, status: Int) {
        let statusText: String
        switch status {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 401: statusText = "Unauthorized"
        case 404: statusText = "Not Found"
        default:  statusText = "Internal Server Error"
        }
        let body = json.data(using: .utf8) ?? Data()
        let cors = "Access-Control-Allow-Origin: *\r\nAccess-Control-Allow-Headers: *\r\nAccess-Control-Allow-Methods: POST, GET, OPTIONS\r\n"
        let response = "HTTP/1.1 \(status) \(statusText)\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\n\(cors)\r\n"
        var data = response.data(using: .utf8) ?? Data()
        data.append(body)
        connection.send(content: data, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    private func sendNotFound(_ connection: NWConnection) {
        sendJSON("{\"error\":\"Not found\"}", connection: connection, status: 404)
    }

    private func extractHeader(_ name: String, from data: Data) -> String? {
        guard let raw = String(data: data, encoding: .utf8) else { return nil }
        for line in raw.components(separatedBy: "\r\n") {
            if line.lowercased().hasPrefix(name.lowercased() + ":") {
                return String(line.dropFirst(name.count + 1)).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private func extractHTTPBody(from data: Data) -> Data {
        guard let raw = String(data: data, encoding: .utf8) else { return data }
        if let range = raw.range(of: "\r\n\r\n") {
            let bodyStart = raw.distance(from: raw.startIndex, to: range.upperBound)
            if bodyStart < data.count {
                return data.advanced(by: bodyStart)
            }
        }
        return data
    }

    private func sanitize(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return String(name.components(separatedBy: invalid).joined(separator: "_").prefix(100))
    }

    // MARK: - Network utilities

    private func generateCode() -> String {
        String(format: "%06d", Int.random(in: 100000...999999))
    }

    private func getLocalIP() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        var ptr = ifaddr
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)
            let addr = current.pointee.ifa_addr.pointee
            if addr.sa_family == UInt8(AF_INET),
               flags & (IFF_UP | IFF_RUNNING) != 0,
               flags & IFF_LOOPBACK == 0 {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(current.pointee.ifa_addr, socklen_t(addr.sa_len),
                            &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                address = String(cString: hostname)
            }
            ptr = current.pointee.ifa_next
        }
        return address
    }

    private func appendLog(_ message: String) {
        DispatchQueue.main.async {
            self.transferLog.append("[\(Date().formatted(date: .omitted, time: .shortened))] \(message)")
            if self.transferLog.count > 100 { self.transferLog.removeFirst() }
        }
    }
}
