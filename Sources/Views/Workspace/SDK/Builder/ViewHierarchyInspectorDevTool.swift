import SwiftUI

struct ViewHierarchyInspectorDevTool: DevTool {
    let id = "view-hierarchy-inspector"
    let name = "View Hierarchy"
    let category = DevToolCategory.diagnostics
    let icon = "layers"
    let description = "Inspect SwiftUI view hierarchy"

    func render() -> some View {
        ViewHierarchyInspectorView()
    }
}

struct ViewHierarchyInspectorView: View {
    @StateObject private var viewModel = ViewHierarchyInspectorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "View Hierarchy Inspector",
                description: "Traverse and inspect the current SwiftUI view tree to debug layout and state propagation.",
                icon: "layers"
            )
            .padding()

            List(viewModel.viewNodes, children: \.children) { node in
                HStack {
                    Image(systemName: "square.stack.3d.up")
                        .foregroundStyle(.secondary)
                    Text(node.name)
                        .font(.caption.bold())
                    Spacer()
                    if let type = node.type {
                        Text(type).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}

struct ViewNode: Identifiable {
    let id = UUID()
    let name: String
    let type: String?
    var children: [ViewNode]?
}

class ViewHierarchyInspectorViewModel: ObservableObject {
    @Published var viewNodes: [ViewNode] = [
        ViewNode(name: "RootWindow", type: "UIWindow", children: [
            ViewNode(name: "HostingController", type: "UIHostingController", children: [
                ViewNode(name: "MainView", type: "SwiftUI.View", children: [
                    ViewNode(name: "NavigationView", type: "SwiftUI.NavigationView"),
                    ViewNode(name: "TabView", type: "SwiftUI.TabView")
                ])
            ])
        ])
    ]
}
