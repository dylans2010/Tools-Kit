import SwiftUI

/// Full-screen list letting users toggle each tool's visibility on the Dashboard.
struct ToolVisibilitySettingsView: View {
    @StateObject private var registry = ToolRegistry()
    @StateObject private var visibility = ToolVisibilityManager.shared

    @State private var searchText = ""

    private var filteredTools: [any Tool] {
        if searchText.isEmpty { return registry.tools }
        return registry.tools.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var visibleCount: Int {
        registry.tools.filter { visibility.isVisible($0.id) }.count
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Label("\(visibleCount) Of \(registry.tools.count) Tools Visible", systemImage: "eye")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Show All") {
                        for tool in registry.tools {
                            visibility.setVisible(tool.id, visible: true)
                        }
                    }
                    .font(.subheadline)
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            }

            ForEach(ToolCategory.allCases, id: \.self) { category in
                let tools = filteredTools.filter { $0.category == category }
                if !tools.isEmpty {
                    Section(category.rawValue) {
                        ForEach(tools, id: \.id) { tool in
                            ToolVisibilityRow(tool: tool, visibility: visibility)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search Tools")
        .navigationTitle("Tool Visibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Row

private struct ToolVisibilityRow: View {
    let tool: any Tool
    @ObservedObject var visibility: ToolVisibilityManager

    var isVisible: Bool {
        visibility.isVisible(tool.id)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: tool.icon)
                .font(.body)
                .foregroundColor(isVisible ? .blue : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(tool.name)
                    .font(.body)
                    .foregroundColor(isVisible ? .primary : .secondary)
                Text(tool.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isVisible },
                set: { visibility.setVisible(tool.id, visible: $0) }
            ))
            .labelsHidden()
        }
    }
}
