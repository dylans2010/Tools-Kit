import Foundation
import Network

/// Connects to iCloud IMAP and fetches emails using raw IMAP over TLS via NWConnection.
/// iCloud IMAP: imap.mail.me.com, port 993, TLS required.
@MainActor
class IMAPClient: ObservableObject {

    // MARK: - Config
    static let host = "imap.mail.me.com"
    static let port: UInt16 = 993

    // MARK: - State
    @Published var emails: [EmailMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isAuthenticated: Bool = false

    private var connection: NWConnection?
    private var responseBuffer: String = ""
    private var commandTag: Int = 1
    private var pendingCompletions: [String: (String) -> Void] = [:]

    // MARK: - Credentials (passed in at connect time, never stored in code)
    private var username: String = ""
    private var password: String = ""  // Must be an Apple App-Specific Password

    // MARK: - Connect & Authenticate
    func connect(username: String, appSpecificPassword: String) {
        self.username = username
        self.password = appSpecificPassword
        isLoading = true
        errorMessage = nil

        let tlsParams = NWParameters.tls
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 30

        connection = NWConnection(
            host: NWEndpoint.Host(Self.host),
            port: NWEndpoint.Port(rawValue: Self.port)!,
            using: tlsParams
        )

        connection?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                switch state {
                case .ready:
                    self?.readGreeting()
                case .failed(let error):
                    self?.errorMessage = "Connection failed: \(error.localizedDescription)"
                    self?.isLoading = false
                case .cancelled:
                    break
                default:
                    break
                }
            }
        }

        connection?.start(queue: .global(qos: .userInitiated))
    }

    // MARK: - Read server greeting then login
    private func readGreeting() {
        receive { [weak self] response in
            guard response.contains("* OK") else {
                self?.errorMessage = "Unexpected greeting: \(response)"
                self?.isLoading = false
                return
            }
            self?.login()
        }
    }

    private func login() {
        let tag = nextTag()
        send("\(tag) LOGIN \"\(username)\" \"\(password)\"") { [weak self] response in
            if response.contains("\(tag) OK") {
                self?.isAuthenticated = true
                self?.selectInbox()
            } else {
                // Common iCloud failure reasons:
                // - "NO [AUTHENTICATIONFAILED]" = wrong password or not App-Specific
                // - "NO [UNAVAILABLE]" = iCloud servers temporarily down
                // - "BAD" = malformed command (check for special chars in password)
                self?.errorMessage = "Login failed: \(response). Ensure you are using an Apple App-Specific Password, not your regular iCloud password."
                self?.isLoading = false
            }
        }
    }

    private func selectInbox() {
        let tag = nextTag()
        send("\(tag) SELECT INBOX") { [weak self] response in
            if response.contains("\(tag) OK") {
                self?.fetchEmailList()
            } else {
                self?.errorMessage = "Could not SELECT INBOX: \(response)"
                self?.isLoading = false
            }
        }
    }

    // MARK: - Fetch Email UIDs
    func fetchEmailList() {
        // Fetch the 50 most recent messages
        let tag = nextTag()
        send("\(tag) FETCH 1:50 (FLAGS ENVELOPE)") { [weak self] response in
            guard let self else { return }
            let parsed = self.parseEnvelopes(from: response)
            self.emails = parsed
            self.isLoading = false
        }
    }

    // MARK: - Fetch Full Body for a Single Email
    func fetchBody(for uid: Int, completion: @escaping (String) -> Void) {
        let tag = nextTag()
        send("\(tag) FETCH \(uid) BODY[TEXT]") { response in
            let body = self.extractBody(from: response)
            DispatchQueue.main.async { completion(body) }
        }
    }

    // MARK: - IMAP Parsing Helpers

    /// Parses FETCH ENVELOPE responses into EmailMessage objects.
    private func parseEnvelopes(from raw: String) -> [EmailMessage] {
        var results: [EmailMessage] = []
        let lines = raw.components(separatedBy: "\r\n")

        for line in lines {
            guard line.contains("ENVELOPE") else { continue }

            // Extract sequence number
            let seqMatch = line.range(of: #"^\* (\d+) FETCH"#, options: .regularExpression)
            let seqNum = seqMatch.map { Int(line[$0].components(separatedBy: " ")[1]) ?? 0 } ?? 0

            // Extract subject (3rd quoted string in ENVELOPE)
            let subject = extractQuoted(from: line, index: 1) ?? "(No Subject)"

            // Extract sender
            let sender = extractSender(from: line)

            // Extract date (1st quoted string)
            let dateString = extractQuoted(from: line, index: 0) ?? ""
            let date = parseIMAPDate(dateString)

            results.append(EmailMessage(
                uid: seqNum,
                subject: subject,
                sender: sender,
                date: date,
                preview: "",
                isRead: line.contains("\\Seen"),
                body: nil
            ))
        }

        return results.reversed() // newest first
    }

    private func extractQuoted(from string: String, index: Int) -> String? {
        var count = 0
        var result = ""
        var inQuote = false
        for char in string {
            if char == "\"" {
                if inQuote {
                    if count == index { return result }
                    inQuote = false
                    result = ""
                    count += 1
                } else {
                    inQuote = true
                }
            } else if inQuote {
                result.append(char)
            }
        }
        return nil
    }

    private func extractSender(from line: String) -> String {
        // ENVELOPE sender field format: (("Name" NIL "user" "domain.com"))
        if let range = line.range(of: #"\(\("([^"]*)" NIL "([^"]*)" "([^"]*)""#, options: .regularExpression) {
            let match = String(line[range])
            let parts = match.components(separatedBy: "\"").filter { !$0.isEmpty && $0 != " NIL " }
            if parts.count >= 3 {
                return "\(parts[0]) <\(parts[1])@\(parts[2])>"
            }
        }
        return "Unknown Sender"
    }

    private func extractBody(from raw: String) -> String {
        guard let start = raw.range(of: "}\r\n")?.upperBound else { return raw }
        let body = String(raw[start...])
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseIMAPDate(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter.date(from: string) ?? Date()
    }

    // MARK: - Low-Level Send/Receive

    private func send(_ command: String, completion: @escaping (String) -> Void) {
        let tag = command.components(separatedBy: " ").first ?? ""
        pendingCompletions[tag] = completion
        let data = (command + "\r\n").data(using: .utf8)!
        connection?.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error {
                Task { @MainActor [weak self] in
                    self?.errorMessage = "Send error: \(error.localizedDescription)"
                }
                return
            }
            Task { @MainActor [weak self] in
                await self?.receiveUntilTagged(tag: tag)
            }
        })
    }

    private func receiveUntilTagged(tag: String) async {
        var accumulated = ""
        while true {
            guard let connection else { return }
            let (data, _, isComplete, error): (Data?, NWConnection.ContentContext?, Bool, NWError?) =
                await withCheckedContinuation { continuation in
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, context, isComplete, error in
                        continuation.resume(returning: (data, context, isComplete, error))
                    }
                }
            if let error {
                errorMessage = "Receive error: \(error.localizedDescription)"
                return
            }
            if let data, let chunk = String(data: data, encoding: .utf8) {
                accumulated += chunk
            }
            if accumulated.contains("\(tag) OK") || accumulated.contains("\(tag) NO") || accumulated.contains("\(tag) BAD") {
                if let completion = pendingCompletions.removeValue(forKey: tag) {
                    completion(accumulated)
                }
                return
            }
            if isComplete { return }
        }
    }

    private func receive(completion: @escaping (String) -> Void) {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, error in
            let response = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            Task { @MainActor in completion(response) }
        }
    }

    private func nextTag() -> String {
        defer { commandTag += 1 }
        return "A\(String(format: "%03d", commandTag))"
    }

    // MARK: - Disconnect
    func disconnect() {
        let tag = nextTag()
        send("\(tag) LOGOUT") { [weak self] _ in
            self?.connection?.cancel()
            self?.connection = nil
        }
    }
}
