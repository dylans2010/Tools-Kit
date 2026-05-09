/*
 REDESIGN SUMMARY:
 - Standardized on sidebar List style for navigation and root area exploration.
 - Modernized search integration using .searchable with Placement.sidebar.
 - Replaced manual button layouts with standard List rows and native Label components.
 - Standardized status rows using monospaced LabeledContent.
 - Replaced manual error/dependency highlighting with semantic SF Symbols and orange tints.
 - strictly preserved all SDKRuntimeWorkspaceState filtering and navigation logic.
 */

import SwiftUI

struct SDKNavigatorView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    private var filteredNodes: [SDKWorkspaceNode] {
        let query = state.navigatorFilterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SDKWorkspaceNode.allCases }
        return SDKWorkspaceNode.allCases.filter { node in
            node.title.localizedCaseInsensitiveContains(query) || node.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(filteredNodes) { node in
                    AreaNodeRow(node: node, isSelected: state.selectedNode == node) {
                        state.open(node: node)
                    }
                }
            } header: {
                Text("Project Areas")
            }

            Section {
                LabeledContent("Libraries") { Text("\(state.libraries.count)").monospaced() }
                LabeledContent("Dependencies") { Text("\(state.dependencies.count)").monospaced() }
                LabeledContent("Diagnostics") {
                    Text("\(state.diagnostics.count)").monospaced()
                        .foregroundStyle(state.diagnostics.isEmpty ? .secondary : .orange)
                }
            } header: {
                Text("System Status")
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $state.navigatorFilterText, placement: .sidebar, prompt: "Search area")
    }
}

// MARK: - Private Subviews

private struct AreaNodeRow: View {
    let node: SDKWorkspaceNode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                HStack {
                    Text(node.title).font(.subheadline)
                    Spacer()
                    if hasError {
                        Image(systemName: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.red)
                    } else if hasDependencies {
                        Circle().fill(.orange).frame(width: 6, height: 6)
                    }
                }
            } icon: {
                Image(systemName: node.icon).foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
        }
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.1) : nil)
    }

    private var hasError: Bool {
        SDKRuntimeWorkspaceState.shared.diagnostics.contains { $0.node == node && $0.severity == .error }
    }
    private var hasDependencies: Bool {
        node == .dependencies && !SDKRuntimeWorkspaceState.shared.dependencies.isEmpty
    }
}
