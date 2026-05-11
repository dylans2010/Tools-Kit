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

// MARK: - Canvas Element System

public struct CanvasElement: Identifiable, Codable, Hashable {
    public var id: UUID
    public var kind: ElementKind
    public var positionX: Double
    public var positionY: Double
    public var width: Double
    public var height: Double
    public var rotation: Double
    public var content: String
    public var colorHex: String
    public var strokeColorHex: String
    public var strokeWidth: Double
    public var fontSize: Double
    public var zIndex: Int
    public var isLocked: Bool

    public init(
        id: UUID = UUID(),
        kind: ElementKind = .text,
        positionX: Double = 100,
        positionY: Double = 100,
        width: Double = 180,
        height: Double = 80,
        rotation: Double = 0,
        content: String = "",
        colorHex: String = "3B82F6",
        strokeColorHex: String = "FFFFFF",
        strokeWidth: Double = 1,
        fontSize: Double = 16,
        zIndex: Int = 0,
        isLocked: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
        self.rotation = rotation
        self.content = content
        self.colorHex = colorHex
        self.strokeColorHex = strokeColorHex
        self.strokeWidth = strokeWidth
        self.fontSize = fontSize
        self.zIndex = zIndex
        self.isLocked = isLocked
    }

    public enum ElementKind: String, Codable, CaseIterable {
        case text
        case stickyNote
        case rectangle
        case circle
        case arrow
        case connector
        case image
        case drawing
        case mediaPlaceholder
    }
}

// MARK: - Legacy CanvasItem (retained for migration)

public struct CanvasItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var kind: CanvasItemKind
    public var positionX: Double
    public var positionY: Double
    public var width: Double
    public var height: Double
    public var rotation: Double
    public var content: String
    public var colorHex: String
    public var zIndex: Int

    public init(
        id: UUID = UUID(),
        kind: CanvasItemKind = .text,
        positionX: Double = 100,
        positionY: Double = 100,
        width: Double = 180,
        height: Double = 80,
        rotation: Double = 0,
        content: String = "",
        colorHex: String = "3B82F6",
        zIndex: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
        self.rotation = rotation
        self.content = content
        self.colorHex = colorHex
        self.zIndex = zIndex
    }

    public enum CanvasItemKind: String, Codable, CaseIterable {
        case text, shape, image, drawing
    }
}

public struct CanvasConnection: Identifiable, Codable, Hashable {
    public var id: UUID
    public var fromItemID: UUID
    public var toItemID: UUID
    public var style: ConnectionStyle

    public init(id: UUID = UUID(), fromItemID: UUID, toItemID: UUID, style: ConnectionStyle = .line) {
        self.id = id
        self.fromItemID = fromItemID
        self.toItemID = toItemID
        self.style = style
    }

    public enum ConnectionStyle: String, Codable, CaseIterable {
        case line, arrow, dashed
    }
}

public struct DrawingPath: Identifiable, Codable, Hashable {
    public var id: UUID
    public var points: [DrawingPoint]
    public var colorHex: String
    public var lineWidth: Double

    public init(id: UUID = UUID(), points: [DrawingPoint] = [], colorHex: String = "FFFFFF", lineWidth: Double = 2) {
        self.id = id
        self.points = points
        self.colorHex = colorHex
        self.lineWidth = lineWidth
    }
}

public struct DrawingPoint: Codable, Hashable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct CanvasState: Codable, Equatable {
    public var elements: [CanvasElement]
    public var items: [CanvasItem]
    public var connections: [CanvasConnection]
    public var drawings: [DrawingPath]
    public var zoom: Double
    public var panX: Double
    public var panY: Double

    public init(
        elements: [CanvasElement] = [],
        items: [CanvasItem] = [],
        connections: [CanvasConnection] = [],
        drawings: [DrawingPath] = [],
        zoom: Double = 1.0,
        panX: Double = 0,
        panY: Double = 0
    ) {
        self.elements = elements
        self.items = items
        self.connections = connections
        self.drawings = drawings
        self.zoom = zoom
        self.panX = panX
        self.panY = panY
    }

    public static func == (lhs: CanvasState, rhs: CanvasState) -> Bool {
        lhs.elements == rhs.elements && lhs.items == rhs.items && lhs.connections == rhs.connections && lhs.drawings == rhs.drawings
    }
}

// MARK: - Store

@MainActor
final class WhiteboardStore: ObservableObject {
    static let shared = WhiteboardStore()

    @Published var boards: [WhiteboardBoard] = []

    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Whiteboards", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private init() {
        loadBoards()
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
        saveAllBoards()
    }

    func updateBoard(_ board: WhiteboardBoard) {
        guard let index = boards.firstIndex(where: { $0.id == board.id }) else { return }
        var updated = board
        updated.updatedAt = Date()
        boards[index] = updated
        saveBoard(updated)
    }

    // MARK: - Persistence

    private func saveBoard(_ board: WhiteboardBoard) {
        do {
            let data = try JSONEncoder().encode(board)
            let fileURL = saveDir.appendingPathComponent("\(board.id.uuidString).json")
            try data.write(to: fileURL)
        } catch {
            print("[WhiteboardStore] Save error: \(error)")
        }
    }

    private func saveAllBoards() {
        for board in boards { saveBoard(board) }
    }

    private func loadBoards() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: saveDir, includingPropertiesForKeys: nil) else { return }
        boards = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> WhiteboardBoard? in
                guard url.lastPathComponent.hasPrefix("canvas_") == false else { return nil }
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(WhiteboardBoard.self, from: data)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - Canvas State Persistence

    func saveCanvasState(_ state: CanvasState, for boardID: UUID) {
        do {
            let data = try JSONEncoder().encode(state)
            let fileURL = saveDir.appendingPathComponent("canvas_\(boardID.uuidString).json")
            try data.write(to: fileURL)
        } catch {
            print("[WhiteboardStore] Canvas state save error: \(error)")
        }
    }

    func loadCanvasState(for boardID: UUID) -> CanvasState? {
        let fileURL = saveDir.appendingPathComponent("canvas_\(boardID.uuidString).json")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(CanvasState.self, from: data)
    }
}
