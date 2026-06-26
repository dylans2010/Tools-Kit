import Foundation
import Observation
import OSLog
import UIKit

public enum OpenClawLogLevel: String, Codable, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

public enum OpenClawLogCategory: String, Codable, CaseIterable, Identifiable {
    public var id: String { self.rawValue }

    case discovery = "Discovery"
    case bonjour = "Bonjour"
    case http = "HTTP"
    case gateway = "Gateway"
    case websocket = "WebSocket"
    case handshake = "Handshake"
    case authentication = "Authentication"
    case pairing = "Pairing"
    case session = "Session"
    case network = "Network"
    case general = "General"
}

public struct OpenClawLogEntry: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let level: OpenClawLogLevel
    public let category: OpenClawLogCategory
    public let title: String
    public let description: String

    // States
    public let connectionState: String
    public let authState: String
    public let pairingState: String
    public let sessionState: String

    public let payload: String?
    public let errorDetails: String?
    public let metadata: [String: String]?

    public init(
        level: OpenClawLogLevel,
        category: OpenClawLogCategory,
        title: String,
        description: String,
        connectionState: String = "N/A",
        authState: String = "N/A",
        pairingState: String = "N/A",
        sessionState: String = "N/A",
        payload: String? = nil,
        error: Error? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.level = level
        self.category = category
        self.title = title
        self.description = description
        self.connectionState = connectionState
        self.authState = authState
        self.pairingState = pairingState
        self.sessionState = sessionState
        self.payload = payload

        if let error = error {
            let nsError = error as NSError
            self.errorDetails = """
            Domain: \(nsError.domain)
            Code: \(nsError.code)
            Description: \(nsError.localizedDescription)
            UserInfo: \(nsError.userInfo)
            """
        } else {
            self.errorDetails = nil
        }
        self.metadata = metadata
    }

    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}

@Observable
public final class OpenClawLoggerService {
    public static let shared = OpenClawLoggerService()

    public private(set) var logs: [OpenClawLogEntry] = []
    private let maxLogs = 5000

    // Diagnostics Summary Stats
    public var errorCount: Int = 0
    public var warningCount: Int = 0
    public var lastErrorTime: Date?
    public var lastHandshakeTime: Date?
    public var activeConnectionStartTime: Date?

    // Current States for Summary
    public var gatewayAddress: String = "None"
    public var connectedServiceName: String = "None"
    public var websocketState: String = "Closed"
    public var protocolVersion: String = "1.0 (Draft)"

    private init() {}

    public func deriveAuthState(from state: OpenClawConnectionState) -> String {
        switch state {
        case .authenticating: return "Authenticating"
        case .authenticated, .ready: return "Authenticated"
        case .failed(let reason): if reason == .serverRejectedAuth { return "Rejected" } else { return "None" }
        default: return "None"
        }
    }

    public func derivePairingState(from state: OpenClawConnectionState) -> String {
        switch state {
        case .pairing: return "Required"
        case .failed(let reason): if reason == .pairingDenied { return "Denied" } else { return "Unknown" }
        default: return "Not Required / Done"
        }
    }

    public func deriveSessionState(from state: OpenClawConnectionState) -> String {
        switch state {
        case .ready: return "Ready"
        case .authenticated: return "Established"
        default: return "Closed"
        }
    }

    /// Thread-safe logging from any context
    public func log(
        level: OpenClawLogLevel = .info,
        category: OpenClawLogCategory = .general,
        title: String,
        description: String = "",
        payload: String? = nil,
        error: Error? = nil,
        metadata: [String: String]? = nil
    ) {
        // Immediate OSLog output for system console
        let logger = Logger(subsystem: "com.toolskit.openclaw", category: category.rawValue)
        let logMessage = "[\(title)] \(description)"
        switch level {
        case .debug: logger.debug("\(logMessage)")
        case .info: logger.info("\(logMessage)")
        case .warning: logger.warning("\(logMessage)")
        case .error: logger.error("\(logMessage)")
        }

        // Capture states on MainActor where OpenClawService lives
        Task { @MainActor in
            let service = OpenClawService.shared
            let connState = service.connectionState
            let connStateStr = "\(connState)"

            // Map specific states for logs
            let authStateStr = self.deriveAuthState(from: connState)
            let pairingStateStr = self.derivePairingState(from: connState)
            let sessionStateStr = self.deriveSessionState(from: connState)

            // Update global summary stats
            if category == .websocket && title == "WebSocket Connected" {
                self.websocketState = "Open"
            } else if category == .websocket && title == "Socket Closed" {
                self.websocketState = "Closed"
            }

            if category == .gateway && title == "Connection Initiated" {
                if let descriptionUrl = description.components(separatedBy: "Target: ").last {
                    self.gatewayAddress = descriptionUrl
                }
            }

            if category == .bonjour && title == "Service Resolved" {
                if let name = description.components(separatedBy: "Name: ").last?.components(separatedBy: ",").first {
                    self.connectedServiceName = name
                }
            }

            let entry = OpenClawLogEntry(
                level: level,
                category: category,
                title: title,
                description: description,
                connectionState: connStateStr,
                authState: authStateStr,
                pairingState: pairingStateStr,
                sessionState: sessionStateStr,
                payload: payload,
                error: error,
                metadata: metadata
            )

            self.addEntry(entry)
        }
    }

    @MainActor
    private func addEntry(_ entry: OpenClawLogEntry) {
        logs.append(entry)
        if logs.count > maxLogs {
            logs.removeFirst()
        }

        updateStats(with: entry)
    }

    @MainActor
    private func updateStats(with entry: OpenClawLogEntry) {
        if entry.level == .error {
            errorCount += 1
            lastErrorTime = entry.timestamp
        } else if entry.level == .warning {
            warningCount += 1
        }

        // Fixed case-sensitivity bug from review
        let titleLower = entry.title.lowercased()
        if entry.category == .handshake && titleLower.contains("successful") {
            lastHandshakeTime = entry.timestamp
            if activeConnectionStartTime == nil {
                activeConnectionStartTime = entry.timestamp
            }
        }

        if entry.category == .gateway && titleLower.contains("disconnected") {
            activeConnectionStartTime = nil
            websocketState = "Closed"
        }
    }

    @MainActor
    public func clear() {
        logs.removeAll()
        errorCount = 0
        warningCount = 0
        lastErrorTime = nil
        lastHandshakeTime = nil
        activeConnectionStartTime = nil
    }

    public func exportAsText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        return logs.map { entry in
            let ts = formatter.string(from: entry.timestamp)
            var text = "[\(ts)] [\(entry.level.rawValue)] [\(entry.category.rawValue)] \(entry.title)"
            if !entry.description.isEmpty {
                text += "\nDescription: \(entry.description)"
            }
            text += "\nStates: Conn=\(entry.connectionState), Auth=\(entry.authState), Pair=\(entry.pairingState), Session=\(entry.sessionState)"
            if let payload = entry.payload {
                text += "\nPayload: \(payload)"
            }
            if let error = entry.errorDetails {
                text += "\nError: \(error)"
            }
            if let metadata = entry.metadata, !metadata.isEmpty {
                text += "\nMetadata: \(metadata)"
            }
            return text
        }.joined(separator: "\n" + String(repeating: "-", count: 40) + "\n")
    }

    public func exportAsJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(logs)
    }
}
