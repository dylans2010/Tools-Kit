import Foundation
import Combine

@MainActor
public final class AISlidesCollaborationEngine: ObservableObject {
    public static let shared = AISlidesCollaborationEngine()

    @Published public private(set) var activeSessions: [SlideCollabSession] = []
    @Published public private(set) var connectedPeers: [CollabPeer] = []
    @Published public private(set) var pendingOperations: [CollabOperation] = []
    @Published public private(set) var conflictQueue: [SlideConflict] = []

    private var operationLog: [CollabOperation] = []

    private init() {}

    // MARK: - Session Management

    public func createSession(deckID: UUID, hostName: String) -> SlideCollabSession {
        let session = SlideCollabSession(deckID: deckID, hostName: hostName)
        activeSessions.append(session)
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "slides.collab",
            name: "session.created",
            data: ["sessionID": session.id.uuidString, "deck": deckID.uuidString]
        ))
        return session
    }

    public func joinSession(sessionID: UUID, peerName: String) -> CollabPeer? {
        guard let index = activeSessions.firstIndex(where: { $0.id == sessionID }) else { return nil }
        let peer = CollabPeer(name: peerName)
        activeSessions[index].peers.append(peer)
        connectedPeers.append(peer)
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "slides.collab",
            name: "peer.joined",
            data: ["peer": peerName, "session": sessionID.uuidString]
        ))
        return peer
    }

    public func leaveSession(sessionID: UUID, peerID: UUID) {
        guard let index = activeSessions.firstIndex(where: { $0.id == sessionID }) else { return }
        activeSessions[index].peers.removeAll { $0.id == peerID }
        connectedPeers.removeAll { $0.id == peerID }
    }

    public func closeSession(id: UUID) {
        activeSessions.removeAll { $0.id == id }
    }

    // MARK: - Operations

    public func submitOperation(_ operation: CollabOperation, sessionID: UUID) {
        guard activeSessions.contains(where: { $0.id == sessionID }) else { return }

        if let conflict = detectConflict(operation) {
            conflictQueue.append(conflict)
            return
        }

        pendingOperations.append(operation)
        operationLog.append(operation)
        applyOperation(operation)

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "slides.collab",
            name: "operation.applied",
            data: ["type": operation.type.rawValue, "slide": "\(operation.slideIndex)"]
        ))
    }

    public func resolveConflict(id: UUID, resolution: ConflictResolution) {
        guard let index = conflictQueue.firstIndex(where: { $0.id == id }) else { return }
        let conflict = conflictQueue.remove(at: index)
        switch resolution {
        case .acceptIncoming:
            applyOperation(conflict.incomingOperation)
        case .keepLocal:
            break
        case .merge:
            applyOperation(conflict.incomingOperation)
        }
    }

    // MARK: - Cursor Tracking

    public func updateCursor(peerID: UUID, slideIndex: Int, position: CursorPosition) {
        if let index = connectedPeers.firstIndex(where: { $0.id == peerID }) {
            connectedPeers[index].cursorSlideIndex = slideIndex
            connectedPeers[index].cursorPosition = position
        }
    }

    // MARK: - Private

    private func applyOperation(_ operation: CollabOperation) {
        pendingOperations.removeAll { $0.id == operation.id }
    }

    private func detectConflict(_ operation: CollabOperation) -> SlideConflict? {
        let concurrent = pendingOperations.first {
            $0.slideIndex == operation.slideIndex &&
            $0.peerID != operation.peerID &&
            abs($0.timestamp.timeIntervalSince(operation.timestamp)) < 2.0
        }
        guard let existing = concurrent else { return nil }
        return SlideConflict(localOperation: existing, incomingOperation: operation)
    }
}

// MARK: - Models

public struct SlideCollabSession: Identifiable {
    public let id: UUID
    public let deckID: UUID
    public let hostName: String
    public var peers: [CollabPeer]
    public let createdAt: Date

    public init(deckID: UUID, hostName: String) {
        self.id = UUID()
        self.deckID = deckID
        self.hostName = hostName
        self.peers = []
        self.createdAt = Date()
    }
}

public struct CollabPeer: Identifiable {
    public let id: UUID
    public let name: String
    public var cursorSlideIndex: Int
    public var cursorPosition: CursorPosition
    public let joinedAt: Date

    public init(name: String) {
        self.id = UUID()
        self.name = name
        self.cursorSlideIndex = 0
        self.cursorPosition = CursorPosition(x: 0, y: 0)
        self.joinedAt = Date()
    }
}

public struct CursorPosition: Codable, Sendable {
    public let x: Double
    public let y: Double
}

public struct CollabOperation: Identifiable {
    public let id: UUID
    public let peerID: UUID
    public let type: CollabOperationType
    public let slideIndex: Int
    public let payload: [String: String]
    public let timestamp: Date

    public init(peerID: UUID, type: CollabOperationType, slideIndex: Int, payload: [String: String] = [:]) {
        self.id = UUID()
        self.peerID = peerID
        self.type = type
        self.slideIndex = slideIndex
        self.payload = payload
        self.timestamp = Date()
    }
}

public enum CollabOperationType: String, Codable, Sendable {
    case insertSlide, deleteSlide, editContent, reorderSlide, changeTheme, addNote
}

public struct SlideConflict: Identifiable {
    public let id: UUID
    public let localOperation: CollabOperation
    public let incomingOperation: CollabOperation
    public let detectedAt: Date

    public init(localOperation: CollabOperation, incomingOperation: CollabOperation) {
        self.id = UUID()
        self.localOperation = localOperation
        self.incomingOperation = incomingOperation
        self.detectedAt = Date()
    }
}

public enum ConflictResolution {
    case acceptIncoming, keepLocal, merge
}
