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
        let spacing: CGFloat = 8
        let horizontalTopPadding: CGFloat = 10
        let compactListStyle: InsetGroupedListStyle = listStyleValueCompact
        let regularListStyle: PlainListStyle = listStyleValue
        let shouldUseCompactListStyle: Bool = isCompact

        return VStack(spacing: spacing) {
            TextField(searchPrompt, text: $state.navigatorFilterText)
                .textFieldStyle(.roundedBorder)
                .padding([.horizontal, .top], horizontalTopPadding)

            let navigatorList = List {
                Section(nodeSectionTitle) {
                    ForEach(filteredNodes) { node in
                        let isSelected: Bool = state.selectedNode == node
                        let iconStyle: Color = isSelected ? .accentColor : .secondary
                        let titleWeight: Font.Weight = isSelected ? .semibold : .regular
                        let titleFont: Font = .subheadline.weight(titleWeight)
                        let tagsText: String = node.tags.joined(separator: " • ")
                        let hasBrokenLinkValue: Bool = hasBrokenLink(for: node)
                        let hasDependencyHighlightValue: Bool = hasDependencyHighlight(for: node)
                        Button {
                            state.open(node: node)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: node.icon)
                                    .frame(width: 22)
                                    .foregroundStyle(iconStyle)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(node.title)
                                        .font(titleFont)
                                    if !isCompact {
                                        Text(tagsText)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if hasBrokenLinkValue {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                } else if hasDependencyHighlightValue {
                                    Circle().fill(.orange).frame(width: 8, height: 8)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section(statusSectionTitle) {
                    let librariesCount: Int = state.libraries.count
                    let dependenciesCount: Int = state.dependencies.count
                    let diagnosticsCount: Int = state.diagnostics.count
                    let librariesValue: String = "\(librariesCount)"
                    let dependenciesValue: String = "\(dependenciesCount)"
                    let diagnosticsValue: String = "\(diagnosticsCount)"

                    LabeledContent("Libraries", value: librariesValue)
                    LabeledContent("Dependencies", value: dependenciesValue)
                    LabeledContent("Diagnostics", value: diagnosticsValue)
                }
            }

            if shouldUseCompactListStyle {
                navigatorList
                    .listStyle(compactListStyle)
            } else {
                navigatorList
                    .listStyle(regularListStyle)
            }
        }
        .background(.background)
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
