import SwiftUI

struct SDKNavigatorView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    private var filteredNodes: [SDKWorkspaceNode] {
        let query = state.navigatorFilterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SDKWorkspaceNode.allCases }
        return SDKWorkspaceNode.allCases.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            TextField("Search navigator", text: $state.navigatorFilterText)
                .textFieldStyle(.roundedBorder)
                .padding([.horizontal, .top], 10)

            List {
                Section("Project Root") {
                    ForEach(filteredNodes) { node in
                        Button {
                            state.open(node: node)
                        } label: {
                            HStack {
                                Image(systemName: node.icon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(node.title)
                                    Text(node.tags.joined(separator: " • "))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if hasBrokenLink(for: node) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                }
                                if hasDependencyHighlight(for: node) {
                                    Circle().fill(.orange).frame(width: 8, height: 8)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(.background)
    }

    private func hasDependencyHighlight(for node: SDKWorkspaceNode) -> Bool {
        node == .dependencies && !state.dependencies.isEmpty
    }

    private func hasBrokenLink(for node: SDKWorkspaceNode) -> Bool {
        state.diagnostics.contains { $0.node == node && $0.severity == .error }
    }
}
