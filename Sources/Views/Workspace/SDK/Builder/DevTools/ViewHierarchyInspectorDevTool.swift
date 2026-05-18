import SwiftUI

struct ViewHierarchyInspectorTool: DevTool {
    let id = UUID()
    let name = "View Hierarchy Inspector"
    let category: DevToolCategory = .diagnostics
    let icon = "square.stack.3d.up"
    let description = "Inspect SwiftUI view hierarchy"
    func render() -> some View { ViewHierarchyInspectorDevToolView() }
}

struct ViewHierarchyInspectorDevToolView: View {
    @State private var hierarchy: [HierarchyNode] = []
    @State private var scanned = false

    struct HierarchyNode: Identifiable {
        let id = UUID()
        let name: String
        let depth: Int
        let type: String
        let childCount: Int
    }

    var body: some View {
        Form {
            Section {
                Button("Scan Hierarchy") { scanHierarchy() }
            }
            if scanned {
                Section("Window Info") {
                    let scenes = UIApplication.shared.connectedScenes
                    LabeledContent("Connected Scenes", value: "\(scenes.count)")
                    ForEach(Array(scenes.enumerated()), id: \.offset) { idx, scene in
                        VStack(alignment: .leading) {
                            Text("Scene \(idx + 1)").font(.caption.bold())
                            Text("State: \(String(describing: scene.activationState.rawValue))")
                                .font(.caption2)
                            if let windowScene = scene as? UIWindowScene {
                                Text("Windows: \(windowScene.windows.count)").font(.caption2)
                            }
                        }
                    }
                }
                Section("View Tree (\(hierarchy.count) nodes)") {
                    ForEach(hierarchy) { node in
                        HStack {
                            Text(String(repeating: "  ", count: node.depth))
                            Image(systemName: node.childCount > 0 ? "folder" : "doc")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading) {
                                Text(node.name).font(.system(.caption, design: .monospaced))
                                Text(node.type).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if node.childCount > 0 {
                                Text("\(node.childCount)").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("View Hierarchy Inspector")
    }

    private func scanHierarchy() {
        hierarchy.removeAll()
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { scanned = true; return }
        scanView(window, depth: 0)
        scanned = true
    }

    private func scanView(_ view: UIView, depth: Int) {
        let name = String(describing: type(of: view))
        hierarchy.append(HierarchyNode(
            name: name, depth: depth,
            type: "\(Int(view.frame.width))x\(Int(view.frame.height))",
            childCount: view.subviews.count
        ))
        if depth < 6 {
            for subview in view.subviews.prefix(5) {
                scanView(subview, depth: depth + 1)
            }
        }
    }
}
