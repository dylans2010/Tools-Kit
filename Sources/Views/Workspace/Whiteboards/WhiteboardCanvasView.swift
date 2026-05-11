import SwiftUI

struct WhiteboardCanvasView: View {
    @State private var board: WhiteboardBoard
    @State private var canvasState: CanvasState
    @State private var showingAddNode = false
    @State private var nodeTitle = ""
    @State private var nodeContent = ""
    @State private var selectedNodeType: WhiteboardNodeType = .idea

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    @State private var draggedNodeID: UUID?
    @State private var edgeSourceID: UUID?
    @State private var isLinkingMode = false
    @State private var isDrawingMode = false
    @State private var currentDrawingPath: DrawingPath?
    @State private var drawingColor: String = "FFFFFF"
    @State private var drawingLineWidth: Double = 2

    private let canvasWidth: CGFloat = 3000
    private let canvasHeight: CGFloat = 2000

    init(board: WhiteboardBoard) {
        _board = State(initialValue: board)
        let loaded = WhiteboardStore.shared.loadCanvasState(for: board.id)
        _canvasState = State(initialValue: loaded ?? CanvasState())
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.02).ignoresSafeArea()

            canvasContent
                .scaleEffect(scale)
                .offset(offset)
                .gesture(isDrawingMode ? nil : panGesture)
                .gesture(magnificationGesture)
                .gesture(isDrawingMode ? drawingGesture : nil)
                .onTapGesture(count: 2) { location in
                    if !isDrawingMode {
                        addNodeAtPosition(location)
                    }
                }
        }
        .navigationTitle(board.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    isDrawingMode.toggle()
                    if isDrawingMode { isLinkingMode = false }
                } label: {
                    Image(systemName: isDrawingMode ? "pencil.circle.fill" : "pencil.circle")
                }
                .help(isDrawingMode ? "Drawing mode ON" : "Draw on canvas")

                Button {
                    isLinkingMode.toggle()
                    if isLinkingMode { isDrawingMode = false }
                } label: {
                    Image(systemName: isLinkingMode ? "link.circle.fill" : "link.circle")
                }
                .help(isLinkingMode ? "Linking mode ON" : "Link nodes")

                Button {
                    showingAddNode = true
                } label: {
                    Image(systemName: "plus")
                }

                Button {
                    withAnimation { scale = 1.0; offset = .zero; lastOffset = .zero }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
        .sheet(isPresented: $showingAddNode) {
            addNodeSheet
        }
        .onDisappear {
            WhiteboardStore.shared.updateBoard(board)
            canvasState.zoom = Double(scale)
            canvasState.panX = Double(offset.width)
            canvasState.panY = Double(offset.height)
            WhiteboardStore.shared.saveCanvasState(canvasState, for: board.id)
        }
    }

    private var canvasContent: some View {
        ZStack(alignment: .topLeading) {
            // Grid background
            Canvas { context, size in
                let gridSpacing: CGFloat = 40
                let lineColor = Color.gray.opacity(0.15)
                for x in stride(from: 0, through: size.width, by: gridSpacing) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                }
                for y in stride(from: 0, through: size.height, by: gridSpacing) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                }
            }
            .frame(width: canvasWidth, height: canvasHeight)

            // Drawing Layer
            ForEach(canvasState.drawings) { drawing in
                Path { path in
                    guard let first = drawing.points.first else { return }
                    path.move(to: CGPoint(x: first.x, y: first.y))
                    for point in drawing.points.dropFirst() {
                        path.addLine(to: CGPoint(x: point.x, y: point.y))
                    }
                }
                .stroke(
                    Color(hex: drawing.colorHex) ?? .white,
                    style: StrokeStyle(lineWidth: drawing.lineWidth, lineCap: .round, lineJoin: .round)
                )
            }

            if let active = currentDrawingPath {
                Path { path in
                    guard let first = active.points.first else { return }
                    path.move(to: CGPoint(x: first.x, y: first.y))
                    for point in active.points.dropFirst() {
                        path.addLine(to: CGPoint(x: point.x, y: point.y))
                    }
                }
                .stroke(
                    Color(hex: active.colorHex) ?? .white,
                    style: StrokeStyle(lineWidth: active.lineWidth, lineCap: .round, lineJoin: .round)
                )
            }

            // Edges
            ForEach(board.edges) { edge in
                if let fromNode = board.nodes.first(where: { $0.id == edge.fromNodeID }),
                   let toNode = board.nodes.first(where: { $0.id == edge.toNodeID }) {
                    Path { path in
                        path.move(to: CGPoint(x: fromNode.positionX + 90, y: fromNode.positionY + 40))
                        path.addLine(to: CGPoint(x: toNode.positionX + 90, y: toNode.positionY + 40))
                    }
                    .stroke(
                        LinearGradient(colors: [.cyan.opacity(0.6), .purple.opacity(0.6)], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                }
            }

            // Nodes
            ForEach(Array(board.nodes.enumerated()), id: \.element.id) { index, node in
                WhiteboardNodeView(node: node)
                    .position(x: node.positionX + 90, y: node.positionY + 40)
                    .overlay(
                        isLinkingMode && edgeSourceID == node.id
                        ? RoundedRectangle(cornerRadius: 10).stroke(Color.cyan, lineWidth: 2).frame(width: 184, height: 80)
                            .position(x: node.positionX + 90, y: node.positionY + 40)
                        : nil
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if isLinkingMode {
                                    if edgeSourceID == nil {
                                        edgeSourceID = node.id
                                    }
                                } else {
                                    board.nodes[index].positionX = value.location.x - 90
                                    board.nodes[index].positionY = value.location.y - 40
                                }
                            }
                            .onEnded { value in
                                if isLinkingMode, let sourceID = edgeSourceID, sourceID != node.id {
                                    let edgeExists = board.edges.contains {
                                        ($0.fromNodeID == sourceID && $0.toNodeID == node.id) ||
                                        ($0.fromNodeID == node.id && $0.toNodeID == sourceID)
                                    }
                                    if !edgeExists {
                                        board.edges.append(WhiteboardEdge(fromNodeID: sourceID, toNodeID: node.id))
                                    }
                                    edgeSourceID = nil
                                } else if isLinkingMode {
                                    edgeSourceID = nil
                                }
                            }
                    )
                    .onTapGesture {
                        if isLinkingMode {
                            if let sourceID = edgeSourceID {
                                if sourceID != node.id {
                                    let edgeExists = board.edges.contains {
                                        ($0.fromNodeID == sourceID && $0.toNodeID == node.id) ||
                                        ($0.fromNodeID == node.id && $0.toNodeID == sourceID)
                                    }
                                    if !edgeExists {
                                        board.edges.append(WhiteboardEdge(fromNodeID: sourceID, toNodeID: node.id))
                                    }
                                }
                                edgeSourceID = nil
                            } else {
                                edgeSourceID = node.id
                            }
                        }
                    }
            }
        }
        .frame(width: canvasWidth, height: canvasHeight)
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isLinkingMode && draggedNodeID == nil {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = max(0.3, min(3.0, value.magnification))
            }
    }

    private var addNodeSheet: some View {
        NavigationStack {
            Form {
                TextField("Node title", text: $nodeTitle)
                TextField("Node content", text: $nodeContent, axis: .vertical)
                    .lineLimit(3...6)
                Picker("Type", selection: $selectedNodeType) {
                    ForEach(WhiteboardNodeType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
            }
            .navigationTitle("New Node")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddNode = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addNode()
                        showingAddNode = false
                    }
                    .disabled(nodeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addNode() {
        let base = Double(board.nodes.count + 1)
        board.nodes.append(
            WhiteboardNode(
                title: nodeTitle,
                content: nodeContent,
                type: selectedNodeType,
                positionX: 120 + (base * 80).truncatingRemainder(dividingBy: 600),
                positionY: 120 + (base * 60).truncatingRemainder(dividingBy: 400)
            )
        )
        nodeTitle = ""
        nodeContent = ""
    }

    private func addNodeAtPosition(_ location: CGPoint) {
        let adjustedX = (location.x - offset.width) / scale
        let adjustedY = (location.y - offset.height) / scale
        board.nodes.append(
            WhiteboardNode(
                title: "New Node",
                content: "",
                type: .idea,
                positionX: adjustedX,
                positionY: adjustedY
            )
        )
    }

    // MARK: - Drawing Gesture

    private var drawingGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let adjustedX = (value.location.x - offset.width) / scale
                let adjustedY = (value.location.y - offset.height) / scale
                let point = DrawingPoint(x: adjustedX, y: adjustedY)

                if currentDrawingPath == nil {
                    currentDrawingPath = DrawingPath(
                        points: [point],
                        colorHex: drawingColor,
                        lineWidth: drawingLineWidth
                    )
                } else {
                    currentDrawingPath?.points.append(point)
                }
            }
            .onEnded { _ in
                if let path = currentDrawingPath, path.points.count > 1 {
                    canvasState.drawings.append(path)
                }
                currentDrawingPath = nil
            }
    }
}
