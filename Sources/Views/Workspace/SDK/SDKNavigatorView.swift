import SwiftUI

struct SDKNavigatorView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private var filteredNodes: [SDKWorkspaceNode] {
        let query = state.navigatorFilterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SDKWorkspaceNode.allCases }
        return SDKWorkspaceNode.allCases.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
        }
    }

    private var isCompact: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    var body: some View {
        VStack(spacing: 8) {
            TextField("Search SDK areas", text: $state.navigatorFilterText)
                .textFieldStyle(.roundedBorder)
                .padding([.horizontal, .top], 10)

            List {
                Section("Project Root") {
                    ForEach(filteredNodes) { node in
                        let isSelected: Bool = state.selectedNode == node
                        let iconStyle: Color = isSelected ? .accentColor : .secondary
                        let titleWeight: Font.Weight = isSelected ? .semibold : .regular
                        Button {
                            state.open(node: node)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: node.icon)
                                    .frame(width: 22)
                                    .foregroundStyle(iconStyle)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(node.title)
                                        .font(.subheadline.weight(titleWeight))
                                    if !isCompact {
                                        Text(node.tags.joined(separator: " • "))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if hasBrokenLink(for: node) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                } else if hasDependencyHighlight(for: node) {
                                    Circle().fill(.orange).frame(width: 8, height: 8)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("SDK Status") {
                    LabeledContent("Libraries", value: "\(state.libraries.count)")
                    LabeledContent("Dependencies", value: "\(state.dependencies.count)")
                    LabeledContent("Diagnostics", value: "\(state.diagnostics.count)")
                }
            }
            .listStyle(isCompact ? .insetGrouped : .plain)
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
