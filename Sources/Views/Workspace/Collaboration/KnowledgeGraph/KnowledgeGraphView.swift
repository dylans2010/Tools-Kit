import SwiftUI

struct KnowledgeGraphView: View {
    @StateObject private var manager = KnowledgeGraphManager.shared
    let spaceID: UUID

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            // Mock Graph Visualization
            Color(.systemBackground)

            GeometryReader { geometry in
                ZStack {
                    // Lines (Edges)
                    Path { path in
                        path.move(to: CGPoint(x: 100, y: 100))
                        path.addLine(to: CGPoint(x: 300, y: 200))
                        path.move(to: CGPoint(x: 300, y: 200))
                        path.addLine(to: CGPoint(x: 150, y: 400))
                    }
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)

                    // Nodes
                    GraphNodeView(label: "Strategic Plan", color: .purple, position: CGPoint(x: 100, y: 100))
                    GraphNodeView(label: "Q3 Budget", color: .green, position: CGPoint(x: 300, y: 200))
                    GraphNodeView(label: "Marketing Slides", color: .orange, position: CGPoint(x: 150, y: 400))
                }
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { offset = $0.translation }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { scale = $0 }
                )
            }
        }
        .navigationTitle("Knowledge Graph")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GraphNodeView: View {
    let label: String
    let color: Color
    let position: CGPoint

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .shadow(radius: 4)
            Text(label)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(4)
        }
        .position(position)
    }
}
