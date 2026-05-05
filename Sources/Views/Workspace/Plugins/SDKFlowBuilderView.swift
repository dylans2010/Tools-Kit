import SwiftUI

struct SDKFlowBuilderView: View {
    @Binding var project: SDKProject
    @State private var nodes: [SDKNode] = []

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                Canvas { context, size in
                    for i in stride(from: 0, to: size.width, by: 40) {
                        context.stroke(Path(CGRect(x: i, y: 0, width: 1, height: size.height)), with: .color(.gray.opacity(0.1)))
                    }
                    for i in stride(from: 0, to: size.height, by: 40) {
                        context.stroke(Path(CGRect(x: 0, y: i, width: size.width, height: 1)), with: .color(.gray.opacity(0.1)))
                    }
                }
                .frame(width: 2000, height: 2000)

                ForEach(nodes) { node in
                    NodeView(node: node)
                        .position(node.position)
                }
            }
        }
        .background(Color(.systemBackground))
        .onAppear(perform: analyzeProject)
        .overlay(alignment: .bottomTrailing) {
            Button(action: addNode) {
                Image(systemName: "plus.circle.fill")
                    .font(.largeTitle)
                    .padding()
            }
        }
    }

    private func analyzeProject() {
        var newNodes: [SDKNode] = []
        if project.sourceCode.contains("workspace.notes") {
            newNodes.append(SDKNode(name: "Module: Notes", type: .trigger, position: CGPoint(x: 200, y: 200)))
        }
        if project.sourceCode.contains("workspace.tasks") {
            newNodes.append(SDKNode(name: "Module: Tasks", type: .action, position: CGPoint(x: 400, y: 300)))
        }
        if newNodes.isEmpty {
            newNodes.append(SDKNode(name: "Entry: Main", type: .trigger, position: CGPoint(x: 100, y: 100)))
        }
        self.nodes = newNodes
    }

    private func addNode() {
        nodes.append(SDKNode(name: "Custom Action", type: .action, position: CGPoint(x: 300, y: 300)))
    }
}

struct SDKNode: Identifiable {
    let id = UUID()
    var name: String
    var type: NodeType
    var position: CGPoint

    enum NodeType {
        case trigger, condition, action
    }
}

struct NodeView: View {
    let node: SDKNode
    var body: some View {
        VStack {
            Text(node.name).font(.caption).bold()
        }
        .padding()
        .background(color.opacity(0.2))
        .background(.background)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 2))
    }

    private var color: Color {
        switch node.type {
        case .trigger: return .blue
        case .condition: return .orange
        case .action: return .green
        }
    }
}
