import SwiftUI

struct SpatialWorkspaceHomeView: View {
    @State private var nodes: [SpatialNode] = [
        SpatialNode(id: UUID(), title: "Project Strategy", type: .note, position: CGPoint(x: 100, y: 100)),
        SpatialNode(id: UUID(), title: "Backend API", type: .task, position: CGPoint(x: 300, y: 200)),
        SpatialNode(id: UUID(), title: "Logo Assets", type: .file, position: CGPoint(x: 150, y: 350))
    ]

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

            ForEach(nodes) { node in
                SpatialNodeView(node: node)
                    .position(node.position)
            }
        }
        .navigationTitle("Spatial Workspace")
        .toolbar {
            Button(action: { /* Add node */ }) {
                Image(systemName: "plus.square.on.square")
            }
        }
    }
}

struct SpatialNode: Identifiable {
    let id: UUID
    var title: String
    var type: NodeType
    var position: CGPoint

    enum NodeType {
        case note, task, file, meeting

        var icon: String {
            switch self {
            case .note: return "note.text"
            case .task: return "checklist"
            case .file: return "doc.fill"
            case .meeting: return "video.fill"
            }
        }

        var color: Color {
            switch self {
            case .note: return .yellow
            case .task: return .blue
            case .file: return .orange
            case .meeting: return .purple
            }
        }
    }
}

struct SpatialNodeView: View {
    let node: SpatialNode

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: node.type.icon)
                .font(.title2)
                .foregroundColor(node.type.color)
            Text(node.title)
                .font(.caption.bold())
        }
        .frame(width: 100, height: 100)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
