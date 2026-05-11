import Foundation
import CoreGraphics

public enum WhiteboardNodeType: String, Codable, CaseIterable {
    case text
    case idea
    case task
    case image
    case group

    var importanceWeight: Double {
        switch self {
        case .text: return 1.0
        case .idea: return 1.35
        case .task: return 1.45
        case .image: return 1.1
        case .group: return 1.25
        }
    }
}

public struct WhiteboardNode: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var content: String
    public var type: WhiteboardNodeType
    public var positionX: Double
    public var positionY: Double

    public init(id: UUID = UUID(), title: String, content: String, type: WhiteboardNodeType = .idea, positionX: Double = 120, positionY: Double = 120) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.positionX = positionX
        self.positionY = positionY
    }
}

public struct WhiteboardEdge: Identifiable, Codable, Hashable {
    public var id: UUID
    public var fromNodeID: UUID
    public var toNodeID: UUID

    public init(id: UUID = UUID(), fromNodeID: UUID, toNodeID: UUID) {
        self.id = id
        self.fromNodeID = fromNodeID
        self.toNodeID = toNodeID
    }
}

public struct WhiteboardBoard: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var nodes: [WhiteboardNode]
    public var edges: [WhiteboardEdge]
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String, nodes: [WhiteboardNode] = [], edges: [WhiteboardEdge] = [], updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.nodes = nodes
        self.edges = edges
        self.updatedAt = updatedAt
    }
}

@MainActor
final class WhiteboardStore: ObservableObject {
    static let shared = WhiteboardStore()

    @Published var boards: [WhiteboardBoard] = []

    private init() {
        if boards.isEmpty {
            boards = [
                WhiteboardBoard(
                    title: "New Strategy Board",
                    nodes: [
                        WhiteboardNode(title: "Vision", content: "One sentence product vision", type: .idea, positionX: 140, positionY: 120),
                        WhiteboardNode(title: "Evidence", content: "Customer interviews and support tickets", type: .text, positionX: 320, positionY: 240),
                        WhiteboardNode(title: "Action", content: "Prioritize onboarding improvements", type: .task, positionX: 520, positionY: 120)
                    ],
                    edges: []
                )
            ]
        }
    }

    func createBoard(named name: String) {
        boards.insert(WhiteboardBoard(title: name), at: 0)
    }

    func updateBoard(_ board: WhiteboardBoard) {
        guard let index = boards.firstIndex(where: { $0.id == board.id }) else { return }
        var updated = board
        updated.updatedAt = Date()
        boards[index] = updated
    }
}
