import SwiftUI

struct IDERuntimeScriptsView: View {
    @Binding var project: SDKProject
    @State private var nodes: [SDKFlowNode] = []

    var body: some View {
        VStack(spacing: 0) {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Flow Builder").font(.headline)
                            Text("Design automation pipelines and runtime hooks.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SDKStatusPill("\(nodes.count) NODES", systemImage: "terminal.fill", color: .blue)
                    }
                }
                .padding()
                .background(.bar)
            }

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
        }
        .navigationTitle("Runtime Scripts")
        .onAppear(perform: analyzeProject)
        .overlay(alignment: .bottomTrailing) {
            Button(action: addNode) {
                Image(systemName: "plus.circle.fill")
                    .font(.largeTitle)
                    .padding()
                    .foregroundStyle(Color.accentColor)
                    .background(Circle().fill(.background).shadow(radius: 4))
            }
            .padding()
        }
    }

    private func analyzeProject() {
        var newNodes: [SDKFlowNode] = []
        if project.sourceCode.contains("workspace.notes") {
            newNodes.append(SDKFlowNode(name: "Module: Notes", type: .trigger, position: CGPoint(x: 200, y: 200)))
        }
        if project.sourceCode.contains("workspace.tasks") {
            newNodes.append(SDKFlowNode(name: "Module: Tasks", type: .action, position: CGPoint(x: 400, y: 300)))
        }
        if newNodes.isEmpty {
            newNodes.append(SDKFlowNode(name: "Entry: Main", type: .trigger, position: CGPoint(x: 100, y: 100)))
        }
        self.nodes = newNodes
    }

    private func addNode() {
        nodes.append(SDKFlowNode(name: "Custom Action", type: .action, position: CGPoint(x: 300, y: 300)))
    }
}
