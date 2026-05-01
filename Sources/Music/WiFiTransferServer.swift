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
    private let preferredPorts: [UInt16] = [8765, 8766, 8767, 8775]

    private init() {}

    // MARK: - Start / Stop

    func start() {
        guard !isRunning else { return }
        pairingCode = generateCode()
        ipAddress = getLocalIP() ?? "—"

        guard let prepared = createListener() else {
            appendLog("Failed to start server. Try another app-free port on the same network.")
            InternalLogger.shared.log("WiFiTransferServer: failed to create listener on preferred ports", level: .error)
            return
        }

        listener = prepared.listener
        port = prepared.port

        listener?.newConnectionHandler = { [weak self] connection in
            connection.start(queue: .global(qos: .userInitiated))
            Task { @MainActor [weak self] in
                self?.handleConnection(connection)
            }
        }
        listener?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
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
        receiveCompleteRequest(from: connection, accumulated: Data())
    }

    private func receiveCompleteRequest(from connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            Task { @MainActor in
                guard let self else {
                    connection.cancel()
                    return
                }

                if let error {
                    self.appendLog("Connection error: \(error.localizedDescription)")
                    connection.cancel()
                    return
                }

                guard let data, !data.isEmpty else {
                    connection.cancel()
                    return
                }

                var buffer = accumulated
                buffer.append(data)

                if !self.requestIsComplete(buffer) {
                    self.receiveCompleteRequest(from: connection, accumulated: buffer)
                    return
                }

                let raw = String(data: buffer, encoding: .utf8) ?? ""
            let lines = raw.components(separatedBy: "\r\n")
            let requestLine = lines.first ?? ""
            let parts = requestLine.components(separatedBy: " ")
            guard parts.count >= 2 else { connection.cancel(); return }
            let method = parts[0]
            let path = parts[1]

            switch (method, path) {
            case ("GET", "/"):
                Task { @MainActor [weak self] in self?.handleRootPage(connection: connection) }
            case ("OPTIONS", _):
                Task { @MainActor [weak self] in self?.sendOptionsOK(connection) }
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
                Task { @MainActor [weak self] in self?.handleUploadChunk(rawRequest: buffer, connection: connection) }
            case ("POST", "/finalize-upload"):
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let body = self.extractHTTPBody(from: buffer)
                    self.handleFinalizeUpload(body: body, connection: connection)
                }
                default:
                    self.sendNotFound(connection)
                }
            }
        }
    }

    // MARK: - Endpoint Handlers

    private func handleValidateCode(body: Data, connection: NWConnection) {
        struct CodeRequest: Decodable { let code: String }
        if let req = try? JSONDecoder().decode(CodeRequest.self, from: body),
           req.code == pairingCode {
            let sessionID = UUID().uuidString
            self.validatedSessions.insert(sessionID)
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

        private func sendOptionsOK(_ connection: NWConnection) {
                let cors = "Access-Control-Allow-Origin: *\r\nAccess-Control-Allow-Headers: *\r\nAccess-Control-Allow-Methods: POST, GET, OPTIONS\r\n"
                let response = "HTTP/1.1 204 No Content\r\n\(cors)Content-Length: 0\r\n\r\n"
                connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                        connection.cancel()
                }))
        }

        private func handleRootPage(connection: NWConnection) {
                let html = """
                <!doctype html>
                <html lang=\"en\">
                <head>
                    <meta charset=\"utf-8\" />
                    <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\" />
                    <title>Tools-Kit WiFi Transfer</title>
                    <style>
                        body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#0f1220;color:#fff;margin:0;padding:24px}
                        .card{max-width:760px;margin:0 auto;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.12);border-radius:20px;padding:20px}
                        input,button{font:inherit;border-radius:12px;border:1px solid rgba(255,255,255,.2);padding:12px}
                        input{background:#1a1f36;color:#fff}
                        button{background:#4f7cff;color:#fff;cursor:pointer}
                        .row{display:flex;gap:10px;flex-wrap:wrap;align-items:center}
                        .muted{opacity:.78;font-size:14px}
                        .ok{color:#7df3a6}.bad{color:#ff8b8b}
                        pre{background:#0b0e19;padding:12px;border-radius:12px;max-height:220px;overflow:auto}
                    </style>
                </head>
                <body>
                    <div class=\"card\">
                        <h2>WiFi Music Transfer</h2>
                        <p class=\"muted\">Enter the pairing code from your iPhone, then upload MP3/M4A/WAV/ZIP files.</p>
                        <div class=\"row\">
                            <input id=\"code\" placeholder=\"Pairing code\" />
                            <button id=\"pair\">Pair</button>
                            <span id=\"pairStatus\" class=\"muted\">Not paired</span>
                        </div>
                        <div class=\"row\" style=\"margin-top:12px\">
                            <input id=\"files\" type=\"file\" multiple />
                            <button id=\"upload\">Upload Files</button>
                        </div>
                        <pre id=\"log\"></pre>
                    </div>
                    <script>
                        let session='';
                        const log=(m)=>{const p=document.getElementById('log');p.textContent += m + '\\n';p.scrollTop=p.scrollHeight;};
                        document.getElementById('pair').onclick=async()=>{
                            const code=document.getElementById('code').value.trim();
                            const res=await fetch('/validate-code',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({code})});
                            const json=await res.json().catch(()=>({}));
                            if(res.ok&&json.session){session=json.session;document.getElementById('pairStatus').textContent='Paired';document.getElementById('pairStatus').className='ok';log('Paired successfully');}
                            else {document.getElementById('pairStatus').textContent='Invalid code';document.getElementById('pairStatus').className='bad';log('Pair failed: '+(json.error||res.status));}
                        };
                        document.getElementById('upload').onclick=async()=>{
                            const files=[...document.getElementById('files').files];
                            if(!session){log('Pair first.');return;}
                            if(!files.length){log('Choose files first.');return;}
                            for(const file of files){
                                const chunkSize=256*1024; const total=Math.ceil(file.size/chunkSize);
                                for(let i=0;i<total;i++){
                                    const chunk=file.slice(i*chunkSize,(i+1)*chunkSize);
                                    const res=await fetch('/upload-chunk',{method:'POST',headers:{'X-Session':session,'X-Filename':file.name,'X-Chunk-Index':String(i)},body:chunk});
                                    if(!res.ok){log('Chunk '+i+' failed for '+file.name);break;}
                                }
                                const done=await fetch('/finalize-upload',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({session,filename:file.name,totalChunks:total})});
                                const payload=await done.json().catch(()=>({}));
                                if(done.ok){log('Uploaded: '+file.name);} else {log('Finalize failed: '+(payload.error||done.status));}
                            }
                        };
                    </script>
                </body>
                </html>
                """

                var data = Data()
                let header = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(html.utf8.count)\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
                data.append(header.data(using: .utf8) ?? Data())
                data.append(html.data(using: .utf8) ?? Data())
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

    private func requestIsComplete(_ data: Data) -> Bool {
        guard let raw = String(data: data, encoding: .utf8),
              let delimiter = raw.range(of: "\r\n\r\n") else {
            return false
        }

        let headerBytes = raw.distance(from: raw.startIndex, to: delimiter.upperBound)
        let headerText = String(raw[..<delimiter.lowerBound])
        let lengthLine = headerText
            .components(separatedBy: "\r\n")
            .first { $0.lowercased().hasPrefix("content-length:") }
        let expectedBodyLength = lengthLine
            .flatMap { Int($0.split(separator: ":", maxSplits: 1).last?.trimmingCharacters(in: .whitespaces) ?? "0") } ?? 0
        let actualBodyLength = max(0, data.count - headerBytes)
        return actualBodyLength >= expectedBodyLength
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
        self.transferLog.append("[\(Date().formatted(date: .omitted, time: .shortened))] \(message)")
        if self.transferLog.count > 100 { self.transferLog.removeFirst() }
    }

    private func createListener() -> (listener: NWListener, port: UInt16)? {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        for candidate in preferredPorts {
            do {
                let nwPort = NWEndpoint.Port(rawValue: candidate) ?? 8765
                let made = try NWListener(using: params, on: nwPort)
                return (made, candidate)
            } catch {
                InternalLogger.shared.log("WiFiTransferServer: port \(candidate) unavailable — \(error)", level: .warning)
            }
        }
        return nil
    }
}
