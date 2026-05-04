import SwiftUI

struct InfiniteCanvasView: View {
    @StateObject private var engine = SpatialEngine.shared
    @StateObject private var graph = NodeGraphEngine.shared

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Grid Background
                CanvasGrid()

                ForEach(graph.nodes) { node in
                    NodeView(node: node)
                        .position(x: node.position.x + engine.offset.x, y: node.position.y + engine.offset.y)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    graph.updateNodePosition(id: node.id, position: value.location)
                                }
                        )
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        engine.pan(by: CGPoint(x: value.translation.width / 10, y: value.translation.height / 10))
                    }
            )
        }
        .background(Color(.systemBackground))
    }
}

struct NodeView: View {
    let node: SpatialNode

    var body: some View {
        VStack {
            Image(systemName: node.entity.type == .note ? "note.text" : "checklist")
            Text(node.entity.title).font(.caption)
        }
        .padding(10)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
    }
}

struct CanvasGrid: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let step: CGFloat = 50
                for x in stride(from: 0, to: geo.size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for y in stride(from: 0, to: geo.size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        }
    }
}
