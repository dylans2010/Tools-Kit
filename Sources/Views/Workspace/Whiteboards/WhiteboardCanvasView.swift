import SwiftUI

struct WhiteboardCanvasView: View {
    @State private var board: WhiteboardBoard
    @State private var canvasState: CanvasState
    @State private var activeTool: WhiteboardViewTools.ToolEntry
    @State private var selectedElementID: UUID?
    @State private var showingAddElement = false
    @State private var showingUnsplash = false

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0

    @State private var currentDrawingPath: DrawingPath?
    @State private var drawingColor: String = "FFFFFF"
    @State private var drawingLineWidth: Double = 2
    @State private var drawingOpacity: Double = 1.0
    @State private var showDrawingCustomizer = false
    @State private var showElementToolbar = false

    @State private var edgeSourceID: UUID?

    @State private var resizeAnchor: ResizeAnchor?
    @State private var resizeStartSize: CGSize = .zero

    private let canvasWidth: CGFloat = 3000
    private let canvasHeight: CGFloat = 2000
    private let tools = WhiteboardViewTools.shared

    enum ResizeAnchor {
        case bottomRight
    }

    init(board: WhiteboardBoard) {
        _board = State(initialValue: board)
        let loaded = WhiteboardStore.shared.loadCanvasState(for: board.id)
        _canvasState = State(initialValue: loaded ?? CanvasState())
        _activeTool = State(initialValue: WhiteboardViewTools.shared.tool(id: "select")!)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.02).ignoresSafeArea()

            canvasContent
                .scaleEffect(scale)
                .offset(offset)
                .gesture(activeTool.interactionMode == .select ? panGesture : nil)
                .gesture(magnificationGesture)
                .gesture(activeTool.interactionMode == .draw ? drawingGesture : nil)
                .onTapGesture { location in
                    handleCanvasTap(at: location)
                }
        }
        .navigationTitle(board.title)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingAddElement) {
            addElementSheet
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingUnsplash) {
            UnsplashImagesView { photo in
                insertUnsplashImage(photo)
            }
        }
        .onDisappear { persistState() }
        .sheet(isPresented: $showDrawingCustomizer) {
            DrawingToolCustomizer(
                tool: activeTool,
                colorHex: $drawingColor,
                lineWidth: $drawingLineWidth,
                opacity: $drawingOpacity
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showElementToolbar) {
            if let idx = selectedElementIndex {
                ElementToolbar(
                    element: $canvasState.elements[idx],
                    onDelete: {
                        deleteElement(id: canvasState.elements[idx].id)
                        showElementToolbar = false
                    },
                    onDuplicate: {
                        duplicateElement(id: canvasState.elements[idx].id)
                        showElementToolbar = false
                    },
                    onBringToFront: { bringToFront(id: canvasState.elements[idx].id) },
                    onSendToBack: { sendToBack(id: canvasState.elements[idx].id) }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .safeAreaInset(edge: .bottom) { toolPalette }
    }

    private var selectedElementIndex: Int? {
        guard let id = selectedElementID else { return nil }
        return canvasState.elements.firstIndex(where: { $0.id == id })
    }

    // MARK: - Tool Palette

    private var toolPalette: some View {
        VStack(spacing: 0) {
            if activeTool.category == .drawing && activeTool.id != "eraser" {
                drawingQuickBar
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(WhiteboardViewTools.ToolCategory.allCases, id: \.self) { category in
                        let categoryTools = tools.tools(for: category)
                        if !categoryTools.isEmpty {
                            toolCategorySection(category: category, tools: categoryTools)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .background(.ultraThinMaterial)
        }
    }

    private func toolCategorySection(category: WhiteboardViewTools.ToolCategory, tools: [WhiteboardViewTools.ToolEntry]) -> some View {
        HStack(spacing: 4) {
            ForEach(tools) { tool in
                Button {
                    let wasSameTool = activeTool.id == tool.id
                    activeTool = tool
                    if tool.category == .drawing && tool.id != "eraser" {
                        drawingColor = tool.configuration.defaultColorHex
                        drawingLineWidth = tool.configuration.defaultStrokeWidth
                        drawingOpacity = tool.configuration.defaultOpacity
                        if wasSameTool {
                            showDrawingCustomizer = true
                        }
                    }
                    selectedElementID = nil
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tool.iconName)
                            .font(.system(size: 16))
                        Text(tool.displayName)
                            .font(.system(size: 8))
                            .lineLimit(1)
                    }
                    .frame(width: 48, height: 42)
                    .background(activeTool.id == tool.id ? Color.accentColor.opacity(0.25) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            if category != WhiteboardViewTools.ToolCategory.allCases.last {
                Divider()
                    .frame(height: 28)
                    .padding(.horizontal, 2)
            }
        }
    }

    private var drawingQuickBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: drawingColor) ?? .white)
                .opacity(drawingOpacity)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))

            Text(String(format: "%.0f", drawingLineWidth))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Slider(value: $drawingLineWidth, in: activeTool.configuration.minStrokeWidth...activeTool.configuration.maxStrokeWidth, step: 0.5)
                .frame(maxWidth: 140)
                .tint(Color(hex: drawingColor) ?? .accentColor)

            Button {
                showDrawingCustomizer = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.accentColor)
                    .padding(6)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.8))
    }

    // MARK: - Canvas Content

    private var canvasContent: some View {
        ZStack(alignment: .topLeading) {
            gridBackground
            drawingsLayer
            activeDrawingLayer
            edgesLayer
            elementsLayer
            nodesLayer
        }
        .frame(width: canvasWidth, height: canvasHeight)
    }

    private var gridBackground: some View {
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
    }

    private var drawingsLayer: some View {
        ForEach(canvasState.drawings) { drawing in
            drawingPathView(for: drawing)
        }
    }

    private func drawingPathView(for drawing: DrawingPath) -> some View {
        Path { path in
            guard let first = drawing.points.first else { return }
            path.move(to: CGPoint(x: first.x, y: first.y))
            for point in drawing.points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }
        }
        .stroke(
            Color(hex: drawing.colorHex) ?? .white,
            style: drawingStrokeStyle(for: drawing)
        )
        .opacity(drawing.opacity)
    }

    private func drawingStrokeStyle(for drawing: DrawingPath) -> StrokeStyle {
        let style = WhiteboardViewTools.DrawingStyle(rawValue: drawing.drawingStyleRaw) ?? .solid
        switch style {
        case .dashed:
            return StrokeStyle(lineWidth: drawing.lineWidth, lineCap: .round, lineJoin: .round, dash: [drawing.lineWidth * 3, drawing.lineWidth * 2])
        case .dotted:
            return StrokeStyle(lineWidth: drawing.lineWidth, lineCap: .round, lineJoin: .round, dash: [1, drawing.lineWidth * 2])
        case .calligraphy:
            return StrokeStyle(lineWidth: drawing.lineWidth, lineCap: .butt, lineJoin: .miter)
        case .chiselTip:
            return StrokeStyle(lineWidth: drawing.lineWidth, lineCap: .butt, lineJoin: .bevel)
        default:
            return StrokeStyle(lineWidth: drawing.lineWidth, lineCap: .round, lineJoin: .round)
        }
    }

    @ViewBuilder
    private var activeDrawingLayer: some View {
        if let active = currentDrawingPath {
            drawingPathView(for: active)
        }
    }

    private var edgesLayer: some View {
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
    }

    // MARK: - Canvas Elements

    private var elementsLayer: some View {
        ForEach(canvasState.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
            CanvasElementView(element: element, isSelected: selectedElementID == element.id)
                .position(x: element.positionX + element.width / 2, y: element.positionY + element.height / 2)
                .gesture(elementDragGesture(for: element))
                .onTapGesture {
                    if activeTool.interactionMode == .select {
                        if selectedElementID == element.id {
                            showElementToolbar = true
                        } else {
                            selectedElementID = element.id
                            showElementToolbar = true
                        }
                    }
                }
                .contextMenu { elementContextMenu(for: element) }
        }
    }

    private var nodesLayer: some View {
        ForEach(Array(board.nodes.enumerated()), id: \.element.id) { index, node in
            WhiteboardNodeView(node: node)
                .position(x: node.positionX + 90, y: node.positionY + 40)
                .gesture(nodeDragGesture(index: index, node: node))
                .onTapGesture { handleNodeTap(node: node) }
        }
    }

    // MARK: - Element Context Menu

    @ViewBuilder
    private func elementContextMenu(for element: CanvasElement) -> some View {
        Button("Delete") { deleteElement(id: element.id) }
        Button(element.isLocked ? "Unlock" : "Lock") { toggleLock(id: element.id) }
        Button("Bring to Front") { bringToFront(id: element.id) }
        Button("Send to Back") { sendToBack(id: element.id) }
    }

    // MARK: - Gestures

    private func elementDragGesture(for element: CanvasElement) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !element.isLocked, activeTool.interactionMode == .select else { return }
                moveElement(id: element.id, to: value.location)
            }
    }

    private func nodeDragGesture(index: Int, node: WhiteboardNode) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard activeTool.interactionMode == .select else { return }
                board.nodes[index].positionX = value.location.x - 90
                board.nodes[index].positionY = value.location.y - 40
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = max(0.3, min(3.0, lastScale * value.magnification))
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

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
                        lineWidth: drawingLineWidth,
                        opacity: drawingOpacity,
                        drawingStyleRaw: activeTool.configuration.drawingStyle.rawValue
                    )
                } else {
                    currentDrawingPath?.points.append(point)
                }
            }
            .onEnded { _ in
                if let path = currentDrawingPath, path.points.count > 1 {
                    if activeTool.id == "eraser" {
                        eraseAtPath(path)
                    } else {
                        canvasState.drawings.append(path)
                    }
                }
                currentDrawingPath = nil
            }
    }

    // MARK: - Tap Handling

    private func handleCanvasTap(at location: CGPoint) {
        let adjustedX = (location.x - offset.width) / scale
        let adjustedY = (location.y - offset.height) / scale

        switch activeTool.interactionMode {
        case .insert:
            insertElementAtPosition(x: adjustedX, y: adjustedY)
        case .select:
            selectedElementID = nil
        case .draw, .transform:
            break
        }
    }

    private func handleNodeTap(node: WhiteboardNode) {
        if activeTool.id == "connector-tool" {
            if let sourceID = edgeSourceID {
                if sourceID != node.id {
                    let exists = board.edges.contains {
                        ($0.fromNodeID == sourceID && $0.toNodeID == node.id) ||
                        ($0.fromNodeID == node.id && $0.toNodeID == sourceID)
                    }
                    if !exists {
                        board.edges.append(WhiteboardEdge(fromNodeID: sourceID, toNodeID: node.id))
                    }
                }
                edgeSourceID = nil
            } else {
                edgeSourceID = node.id
            }
        }
    }

    // MARK: - Element Operations

    private func insertElementAtPosition(x: Double, y: Double) {
        let kind: CanvasElement.ElementKind
        let width: Double
        let height: Double
        let content: String
        let colorHex: String

        switch activeTool.id {
        case "sticky-note":
            kind = .stickyNote
            width = 200; height = 150
            content = ""; colorHex = "FBBF24"
        case "rectangle":
            kind = .rectangle
            width = 160; height = 100
            content = ""; colorHex = "3B82F6"
        case "circle":
            kind = .circle
            width = 120; height = 120
            content = ""; colorHex = "8B5CF6"
        case "text-tool":
            kind = .text
            width = 200; height = 60
            content = "Text"; colorHex = "F9FAFB"
        case "arrow":
            kind = .arrow
            width = 160; height = 40
            content = ""; colorHex = "FFFFFF"
        case "media-placeholder":
            kind = .mediaPlaceholder
            width = 240; height = 160
            content = ""; colorHex = "6B7280"
        default:
            return
        }

        let element = CanvasElement(
            kind: kind,
            positionX: x - width / 2,
            positionY: y - height / 2,
            width: width,
            height: height,
            content: content,
            colorHex: colorHex,
            zIndex: (canvasState.elements.map(\.zIndex).max() ?? 0) + 1
        )
        canvasState.elements.append(element)
    }

    private func moveElement(id: UUID, to location: CGPoint) {
        guard let index = canvasState.elements.firstIndex(where: { $0.id == id }) else { return }
        let element = canvasState.elements[index]
        canvasState.elements[index].positionX = location.x - element.width / 2
        canvasState.elements[index].positionY = location.y - element.height / 2
    }

    private func deleteElement(id: UUID) {
        canvasState.elements.removeAll { $0.id == id }
        if selectedElementID == id { selectedElementID = nil }
    }

    private func toggleLock(id: UUID) {
        guard let index = canvasState.elements.firstIndex(where: { $0.id == id }) else { return }
        canvasState.elements[index].isLocked.toggle()
    }

    private func bringToFront(id: UUID) {
        guard let index = canvasState.elements.firstIndex(where: { $0.id == id }) else { return }
        let maxZ = canvasState.elements.map(\.zIndex).max() ?? 0
        canvasState.elements[index].zIndex = maxZ + 1
    }

    private func sendToBack(id: UUID) {
        guard let index = canvasState.elements.firstIndex(where: { $0.id == id }) else { return }
        let minZ = canvasState.elements.map(\.zIndex).min() ?? 0
        canvasState.elements[index].zIndex = minZ - 1
    }

    private func duplicateElement(id: UUID) {
        guard let index = canvasState.elements.firstIndex(where: { $0.id == id }) else { return }
        let source = canvasState.elements[index]
        var copy = source
        copy.id = UUID()
        copy.positionX += 20
        copy.positionY += 20
        copy.zIndex = (canvasState.elements.map(\.zIndex).max() ?? 0) + 1
        canvasState.elements.append(copy)
        selectedElementID = copy.id
    }

    private func eraseAtPath(_ path: DrawingPath) {
        let eraseThreshold: Double = 20
        canvasState.drawings.removeAll { drawing in
            drawing.points.contains { dp in
                path.points.contains { ep in
                    let dx = dp.x - ep.x
                    let dy = dp.y - ep.y
                    return (dx * dx + dy * dy) < eraseThreshold * eraseThreshold
                }
            }
        }
    }

    // MARK: - Unsplash Image Insertion

    private func insertUnsplashImage(_ photo: UnsplashPhoto) {
        let centerX = canvasWidth / 2
        let centerY = canvasHeight / 2
        let aspectRatio = Double(photo.width) / max(Double(photo.height), 1)
        let elementWidth: Double = 280
        let elementHeight = elementWidth / aspectRatio

        let element = CanvasElement(
            kind: .image,
            positionX: centerX - elementWidth / 2,
            positionY: centerY - elementHeight / 2,
            width: elementWidth,
            height: elementHeight,
            content: photo.urls.regular,
            colorHex: "6B7280",
            zIndex: (canvasState.elements.map(\.zIndex).max() ?? 0) + 1
        )
        canvasState.elements.append(element)
        selectedElementID = element.id
    }

    // MARK: - State Persistence

    private func persistState() {
        WhiteboardStore.shared.updateBoard(board)
        canvasState.zoom = Double(scale)
        canvasState.panX = Double(offset.width)
        canvasState.panY = Double(offset.height)
        WhiteboardStore.shared.saveCanvasState(canvasState, for: board.id)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                showingAddElement = true
            } label: {
                Image(systemName: "plus")
            }

            Button {
                withAnimation { scale = 1.0; offset = .zero; lastOffset = .zero; lastScale = 1.0 }
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }

            if selectedElementID != nil {
                Button {
                    if let id = selectedElementID {
                        deleteElement(id: id)
                    }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    // MARK: - Add Element Sheet

    private var addElementSheet: some View {
        NavigationStack {
            List {
                WhiteboardDrawingToolsSection(tools: tools.tools(for: .drawing)) { tool in
                    activeTool = tool
                    drawingColor = tool.configuration.defaultColorHex
                    drawingLineWidth = tool.configuration.defaultStrokeWidth
                    drawingOpacity = tool.configuration.defaultOpacity
                    showingAddElement = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showDrawingCustomizer = true
                    }
                }
                Section("Shapes") {
                    addElementButton(label: "Rectangle", icon: "rectangle", toolID: "rectangle")
                    addElementButton(label: "Circle", icon: "circle", toolID: "circle")
                    addElementButton(label: "Arrow", icon: "arrow.right", toolID: "arrow")
                }
                Section("Annotations") {
                    addElementButton(label: "Sticky Note", icon: "note.text", toolID: "sticky-note")
                    addElementButton(label: "Text", icon: "textformat", toolID: "text-tool")
                }
                Section("Media") {
                    addElementButton(label: "Media Placeholder", icon: "photo", toolID: "media-placeholder")
                    Button {
                        showingAddElement = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingUnsplash = true
                        }
                    } label: {
                        Label("Unsplash Image", systemImage: "photo.on.rectangle.angled")
                    }
                }
                Section("Nodes") {
                    addNodeButton()
                }
            }
            .navigationTitle("Add Element")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showingAddElement = false }
                }
            }
        }
    }

    private func addElementButton(label: String, icon: String, toolID: String) -> some View {
        Button {
            let centerX = canvasWidth / 2
            let centerY = canvasHeight / 2
            if let tool = tools.tool(id: toolID) {
                activeTool = tool
            }
            insertElementAtPosition(x: centerX, y: centerY)
            showingAddElement = false
        } label: {
            Label(label, systemImage: icon)
        }
    }

    private func addNodeButton() -> some View {
        Button {
            let base = Double(board.nodes.count + 1)
            board.nodes.append(
                WhiteboardNode(
                    title: "Node \(board.nodes.count + 1)",
                    content: "",
                    type: .idea,
                    positionX: 120 + (base * 80).truncatingRemainder(dividingBy: 600),
                    positionY: 120 + (base * 60).truncatingRemainder(dividingBy: 400)
                )
            )
            showingAddElement = false
        } label: {
            Label("Idea Node", systemImage: "lightbulb")
        }
    }
}

// MARK: - Canvas Element View

struct CanvasElementView: View {
    let element: CanvasElement
    let isSelected: Bool

    var body: some View {
        Group {
            switch element.kind {
            case .text:
                textElement
            case .stickyNote:
                stickyNoteElement
            case .rectangle:
                rectangleElement
            case .circle:
                circleElement
            case .arrow:
                arrowElement
            case .connector:
                connectorElement
            case .image, .mediaPlaceholder:
                mediaElement
            case .drawing:
                EmptyView()
            }
        }
        .frame(width: element.width, height: element.height)
        .rotationEffect(.degrees(element.rotation))
        .overlay(selectionOverlay)
    }

    private var textElement: some View {
        Text(element.content.isEmpty ? "Text" : element.content)
            .font(.system(size: element.fontSize))
            .foregroundStyle(.white)
            .frame(width: element.width, height: element.height)
    }

    private var stickyNoteElement: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(element.content.isEmpty ? "Note" : element.content)
                .font(.system(size: 14))
                .foregroundStyle(.black)
                .lineLimit(6)
        }
        .padding(8)
        .frame(width: element.width, height: element.height)
        .background(Color(hex: element.colorHex) ?? .yellow)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 2)
    }

    private var rectangleElement: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hex: element.colorHex)?.opacity(0.3) ?? Color.blue.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: element.strokeColorHex) ?? .white, lineWidth: element.strokeWidth)
            )
    }

    private var circleElement: some View {
        Circle()
            .fill(Color(hex: element.colorHex)?.opacity(0.3) ?? Color.purple.opacity(0.3))
            .overlay(
                Circle()
                    .stroke(Color(hex: element.strokeColorHex) ?? .white, lineWidth: element.strokeWidth)
            )
    }

    private var arrowElement: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                path.addLine(to: CGPoint(x: geo.size.width - 12, y: geo.size.height / 2))
                path.move(to: CGPoint(x: geo.size.width - 12, y: geo.size.height / 2))
                path.addLine(to: CGPoint(x: geo.size.width - 20, y: geo.size.height / 2 - 8))
                path.move(to: CGPoint(x: geo.size.width - 12, y: geo.size.height / 2))
                path.addLine(to: CGPoint(x: geo.size.width - 20, y: geo.size.height / 2 + 8))
            }
            .stroke(Color(hex: element.colorHex) ?? .white, lineWidth: 2)
        }
    }

    private var connectorElement: some View {
        Rectangle()
            .fill(Color(hex: element.colorHex)?.opacity(0.2) ?? Color.gray.opacity(0.2))
            .overlay(
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color(hex: element.strokeColorHex) ?? .gray)
            )
    }

    private var mediaElement: some View {
        Group {
            if let url = URL(string: element.content), !element.content.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderMedia
                    case .empty:
                        Color.gray.opacity(0.1)
                            .overlay { ProgressView() }
                    @unknown default:
                        placeholderMedia
                    }
                }
            } else {
                placeholderMedia
            }
        }
        .frame(width: element.width, height: element.height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderMedia: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Media")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: element.width, height: element.height)
        .background(Color(hex: element.colorHex)?.opacity(0.15) ?? Color.gray.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(.secondary)
        )
    }

    @ViewBuilder
    private var selectionOverlay: some View {
        if isSelected {
            Rectangle()
                .stroke(Color.accentColor, lineWidth: 2)
                .overlay(alignment: .topLeading) {
                    Circle().fill(Color.accentColor).frame(width: 8, height: 8).offset(x: -4, y: -4)
                }
                .overlay(alignment: .topTrailing) {
                    Circle().fill(Color.accentColor).frame(width: 8, height: 8).offset(x: 4, y: -4)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle().fill(Color.accentColor).frame(width: 8, height: 8).offset(x: -4, y: 4)
                }
                .overlay(alignment: .bottomTrailing) {
                    Circle().fill(Color.accentColor).frame(width: 8, height: 8).offset(x: 4, y: 4)
                }
        }
    }
}
