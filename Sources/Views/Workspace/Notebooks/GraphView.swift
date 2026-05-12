import SwiftUI

struct GraphView: View {
    @ObservedObject var manager = NotebooksManager.shared
    @State private var dragOffset: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0

    struct Node: Identifiable, Sendable {
        let id: UUID
        let title: String
        var position: CGPoint
    }

    struct Link: Identifiable, Sendable {
        let id = UUID()
        let source: UUID
        let target: UUID
    }

    @State private var nodes: [Node] = []
    @State private var links: [Link] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                // Draw links
                ForEach(links) { link in
                    if let source = nodes.first(where: { $0.id == link.source }),
                       let target = nodes.first(where: { $0.id == link.target }) {
                        Path { path in
                            path.move(to: source.position)
                            path.addLine(to: target.position)
                        }
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    }
                }

                // Draw nodes
                ForEach($nodes) { $node in
                    NodeView(node: $node)
                }
            }
            .scaleEffect(zoomScale)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in dragOffset = value.translation }
            )
            .onAppear {
                generateGraph(in: geo.size)
            }
        }
        .navigationTitle("Knowledge Graph")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateGraph(in size: CGSize) {
        var newNodes: [Node] = []
        var newLinks: [Link] = []

        let pages = manager.notebooks.flatMap { $0.folders.flatMap(\.pages) }

        for (index, page) in pages.prefix(20).enumerated() {
            let angle = Double(index) / Double(min(pages.count, 20)) * 2.0 * .pi
            let radius = min(size.width, size.height) * 0.3
            let x = size.width / 2 + CGFloat(cos(angle)) * radius
            let y = size.height / 2 + CGFloat(sin(angle)) * radius

            let node = Node(id: page.id, title: page.title, position: CGPoint(x: x, y: y))
            newNodes.append(node)
        }

        // Add some random links for visualization
        if newNodes.count > 1 {
            for i in 0..<newNodes.count {
                let targetIdx = (i + 1) % newNodes.count
                newLinks.append(Link(source: newNodes[i].id, target: newNodes[targetIdx].id))
            }
        }

        self.nodes = newNodes
        self.links = newLinks
    }
}

private struct NodeView: View {
    @Binding var node: GraphView.Node

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom))
                .frame(width: 40, height: 40)
                .shadow(radius: 4)

            Text(node.title)
                .font(.caption2.bold())
                .foregroundStyle(.primary)
                .frame(width: 80)
                .lineLimit(1)
        }
        .position(node.position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    node.position = value.location
                }
        )
    }
}
