import SwiftUI

struct SpatialWorkspaceHomeView: View {
    @State private var canvas: SpatialCanvas = SpatialCanvas(id: UUID(), name: "Default Canvas", nodes: [], lastModified: Date())

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            // Grid Background
            Canvas { context, size in
                let step: CGFloat = 40
                for x in stride(from: 0, to: size.width, by: step) {
                    context.stroke(Path(CGRect(x: x, y: 0, width: 0.5, height: size.height)), with: .color(.gray.opacity(0.1)))
                }
                for y in stride(from: 0, to: size.height, by: step) {
                    context.stroke(Path(CGRect(x: 0, y: y, width: size.width, height: 0.5)), with: .color(.gray.opacity(0.1)))
                }
            }

            ForEach(canvas.nodes) { node in
                SpatialNodeView(node: node)
                    .position(node.position)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                updateNodePosition(node.id, to: value.location)
                            }
                            .onEnded { _ in
                                saveCanvas()
                            }
                    )
            }
        }
        .navigationTitle(canvas.name)
        .toolbar {
            Button(action: addNode) {
                Image(systemName: "plus.square.on.square")
            }
        }
        .onAppear(perform: loadCanvas)
    }

    private func loadCanvas() {
        if let existing = UnifiedDataStore.shared.loadCanvases().first {
            self.canvas = existing
        } else {
            canvas.nodes = [
                SpatialNode(id: UUID(), title: "Project Strategy", type: .note, position: CGPoint(x: 100, y: 100)),
                SpatialNode(id: UUID(), title: "Backend API", type: .task, position: CGPoint(x: 300, y: 200))
            ]
            saveCanvas()
        }
    }

    private func saveCanvas() {
        canvas.lastModified = Date()
        try? UnifiedDataStore.shared.saveCanvas(canvas)
    }

    private func addNode() {
        let newNode = SpatialNode(id: UUID(), title: "New Item", type: .note, position: CGPoint(x: 200, y: 200))
        canvas.nodes.append(newNode)
        saveCanvas()
    }

    private func updateNodePosition(_ id: UUID, to position: CGPoint) {
        if let index = canvas.nodes.firstIndex(where: { $0.id == id }) {
            canvas.nodes[index].position = position
        }
    }
}

struct SpatialNodeView: View {
    let node: SpatialNode

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: nodeIcon)
                .font(.title2)
                .foregroundColor(nodeColor)
            Text(node.title)
                .font(.caption.bold())
        }
        .frame(width: 100, height: 100)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private var nodeIcon: String {
        switch node.type {
        case .note: return "note.text"
        case .task: return "checklist"
        case .file: return "doc.fill"
        case .meeting: return "video.fill"
        }
    }

    private var nodeColor: Color {
        switch node.type {
        case .note: return .yellow
        case .task: return .blue
        case .file: return .orange
        case .meeting: return .purple
        }
    }
}
