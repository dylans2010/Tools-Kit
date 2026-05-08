import SwiftUI

struct SDKNavigatorView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private var filteredNodes: [SDKWorkspaceNode] {
        let query: String = state.navigatorFilterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SDKWorkspaceNode.allCases }

        let allNodes: [SDKWorkspaceNode] = SDKWorkspaceNode.allCases
        let matchingNodes: [SDKWorkspaceNode] = allNodes.filter { node in
            let titleMatches: Bool = node.title.localizedCaseInsensitiveContains(query)
            let tagMatches: Bool = node.tags.contains { tag in
                let matchesQuery: Bool = tag.localizedCaseInsensitiveContains(query)
                return matchesQuery
            }
            let nodeMatches: Bool = titleMatches || tagMatches
            return nodeMatches
        }
        return matchingNodes
    }

    private var isCompact: Bool {
        #if os(iOS)
        let sizeClass: UserInterfaceSizeClass? = horizontalSizeClass
        let compactSizeClass: UserInterfaceSizeClass = .compact
        let isCompactSizeClass: Bool = sizeClass == compactSizeClass
        return isCompactSizeClass
        #else
        let compactLayout: Bool = false
        return compactLayout
        #endif
    }

    private var listStyleValue: PlainListStyle {
        let plainStyle: PlainListStyle = .plain
        return plainStyle
    }

    private var listStyleValueCompact: InsetGroupedListStyle {
        let groupedStyle: InsetGroupedListStyle = .insetGrouped
        return groupedStyle
    }

    private var nodeSectionTitle: LocalizedStringKey {
        let title: LocalizedStringKey = "Project Root"
        return title
    }

    private var statusSectionTitle: LocalizedStringKey {
        let title: LocalizedStringKey = "SDK Status"
        return title
    }

    private var searchPrompt: String {
        let prompt: String = "Search SDK areas"
        return prompt
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(searchPrompt, text: $state.navigatorFilterText)
                    .font(.subheadline)
            }
            .padding(8)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()

            List {
                Section {
                    ForEach(filteredNodes) { node in
                        nodeButton(for: node)
                    }
                } header: {
                    Text(nodeSectionTitle)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button { state.open(node: .libraries) } label: {
                        statusRow(title: "Libraries", value: "\(state.libraries.count)", icon: "shippingbox")
                    }
                    .buttonStyle(.plain)

                    Button { state.open(node: .dependencies) } label: {
                        statusRow(title: "Dependencies", value: "\(state.dependencies.count)", icon: "link")
                    }
                    .buttonStyle(.plain)

                    Button { state.open(node: .diagnostics) } label: {
                        statusRow(title: "Diagnostics", value: "\(state.diagnostics.count)", icon: "stethoscope")
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text(statusSectionTitle)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func nodeButton(for node: SDKWorkspaceNode) -> some View {
        let isSelected: Bool = state.selectedNode == node
        let titleFontWeight: Font.Weight = isSelected ? .medium : .regular
        let iconStyle: Color = isSelected ? .blue : .secondary
        let titleStyle: Color = isSelected ? .primary : Color.primary.opacity(0.8)
        let backgroundColor: Color = isSelected ? Color.blue.opacity(0.1) : .clear

        return Button {
            state.open(node: node)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: node.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundStyle(iconStyle)

                Text(node.title)
                    .font(.system(size: 13, weight: titleFontWeight))
                    .foregroundStyle(titleStyle)

                Spacer()

                if hasBrokenLink(for: node) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                } else if hasDependencyHighlight(for: node) {
                    Circle().fill(.orange).frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    private func statusRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 12))
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.05), in: Capsule())
        }
    }

    private func hasDependencyHighlight(for node: SDKWorkspaceNode) -> Bool {
        let isDependencyNode: Bool = node == .dependencies
        let hasDependencies: Bool = !state.dependencies.isEmpty
        let shouldHighlight: Bool = isDependencyNode && hasDependencies
        return shouldHighlight
    }

    private func hasBrokenLink(for node: SDKWorkspaceNode) -> Bool {
        let hasMatchingDiagnostic: Bool = state.diagnostics.contains { diagnostic in
            let nodeMatches: Bool = diagnostic.node == node
            let severityMatches: Bool = diagnostic.severity == .error
            let isBrokenLink: Bool = nodeMatches && severityMatches
            return isBrokenLink
        }
        return hasMatchingDiagnostic
    }
}
