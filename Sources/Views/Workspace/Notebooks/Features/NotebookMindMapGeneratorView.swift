import SwiftUI

struct NotebookMindMapGeneratorView: View {
    @StateObject private var manager = NotebooksManager.shared
    @State private var nodes: [MindMapNode] = []

    struct MindMapNode: Identifiable {
        let id = UUID()
        let title: String
        let position: CGPoint
        let connections: [UUID]
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                // Connections (Simplified as background lines)
                if nodes.count > 1 {
                    Path { path in
                        for i in 0..<nodes.count - 1 {
                            path.move(to: nodes[i].position)
                            path.addLine(to: nodes[i+1].position)
                        }
                    }
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 2)
                }

                ForEach(nodes) { node in
                    Text(node.title)
                        .font(.caption.bold())
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.accentColor.opacity(0.3)))
                        .position(node.position)
                }
            }
            .frame(width: 1000, height: 1000)
        }
        .navigationTitle("Mind Map")
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: generateMap)
    }

    private func generateMap() {
        var newNodes: [MindMapNode] = []
        let center = CGPoint(x: 500, y: 500)

        let allPages = manager.notebooks.flatMap { $0.folders.flatMap { $0.pages } }

        for (index, page) in allPages.prefix(15).enumerated() {
            let angle = Double(index) / Double(min(allPages.count, 15)) * 2.0 * .pi
            let radius = 250.0
            let pos = CGPoint(
                x: center.x + CGFloat(cos(angle) * radius),
                y: center.y + CGFloat(sin(angle) * radius)
            )
            newNodes.append(MindMapNode(title: page.title, position: pos, connections: []))
        }

        // Add root node
        newNodes.append(MindMapNode(title: "My Notebooks", position: center, connections: []))

        nodes = newNodes
    }
}
