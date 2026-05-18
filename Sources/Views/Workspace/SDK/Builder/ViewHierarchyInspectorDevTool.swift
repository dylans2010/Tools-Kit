import SwiftUI

struct ViewHierarchyInspectorDevTool: DevTool {
    let id = "view-hierarchy-inspector"
    let name = "View Hierarchy Inspector"
    let category = DevToolCategory.diagnostics
    let icon = "square.stack.3d.up"
    let description = "Inspect SwiftUI view hierarchy"

    func render() -> some View {
        ViewHierarchyInspectorView()
    }
}

struct ViewHierarchyInspectorView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("VStack").font(.monospaced(.body)())
                HStack {
                    Text("  ").font(.monospaced(.body)())
                    Text("ScrollView").font(.monospaced(.body)())
                }
                HStack {
                    Text("    ").font(.monospaced(.body)())
                    Text("VStack").font(.monospaced(.body)())
                }
                HStack {
                    Text("      ").font(.monospaced(.body)())
                    Text("Text (App State Inspector)").font(.monospaced(.body)())
                }

                Text("\nNote: Real hierarchy requires instrumentation. Showing static structural map of active view.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
