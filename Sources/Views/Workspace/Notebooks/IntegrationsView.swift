import SwiftUI

struct IntegrationsView: View {
    @StateObject private var manager = NotebooksManager.shared
    @State private var showingCreate = false
    @State private var editingTool: IntegrationTool? = nil
    @State private var searchText = ""
    @State private var showEnabledOnly = false
    @State private var selectedCategory = "All"

    private var categories: [String] {
        let values = Set(manager.integrations.map { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        return ["All"] + values.sorted()
    }

    private var filteredTools: [IntegrationTool] {
        manager.integrations.filter { tool in
            let matchesEnabled = !showEnabledOnly || tool.isEnabled
            let matchesCategory = selectedCategory == "All" || tool.category == selectedCategory
            let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = text.isEmpty || [tool.name, tool.description, tool.category, tool.promptTemplate]
                .joined(separator: " ")
                .localizedCaseInsensitiveContains(text)
            return matchesEnabled && matchesCategory && matchesSearch
        }
        .sorted {
            if $0.isEnabled != $1.isEnabled { return $0.isEnabled && !$1.isEnabled }
            return $0.updatedAt > $1.updatedAt
        }
    }

    var body: some View {
        List {
            statsSection
            filtersSection
            toolsSection
        }
        .navigationTitle("Integrations")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search tools")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button("Enable All") { bulkSetEnabled(true) }
                    Button("Disable All") { bulkSetEnabled(false) }
                    Button("Delete Disabled", role: .destructive) { deleteDisabled() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }

                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            IntegrationEditorView(tool: nil)
        }
        .sheet(item: $editingTool) { tool in
            IntegrationEditorView(tool: tool)
        }
    }

    private var statsSection: some View {
        Section {
            HStack(spacing: 10) {
                statChip(title: "Total", value: "\(manager.integrations.count)", color: .indigo)
                statChip(title: "Enabled", value: "\(manager.integrations.filter(\.isEnabled).count)", color: .green)
                statChip(title: "Categories", value: "\(Set(manager.integrations.map(\.category)).count)", color: .orange)
            }
            .padding(.vertical, 2)
        }
    }

    private var filtersSection: some View {
        Section {
            Toggle("Enabled Only", isOn: $showEnabledOnly)
            Picker("Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
        } header: {
            Text("Filters")
        }
    }

    @ViewBuilder
    private var toolsSection: some View {
        if filteredTools.isEmpty {
            Section {
                ContentUnavailableView(
                    "No Matching Integrations",
                    systemImage: "puzzlepiece.extension",
                    description: Text("Create advanced tools with custom prompts, triggers, and output rules.")
                )
            }
        } else {
            Section {
                ForEach(filteredTools) { tool in
                    toolRow(tool)
                }
            } header: {
                Text("Tools")
            }
        }
    }

    private func toolRow(_ tool: IntegrationTool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(tool.name)
                    .font(.headline)
                    .lineLimit(1)
                if tool.isEnabled {
                    WorkspaceStatusBadge(title: "Enabled", color: .green)
                } else {
                    WorkspaceStatusBadge(title: "Disabled", color: .secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { tool.isEnabled },
                    set: { newValue in toggleEnabled(tool, to: newValue) }
                ))
                .labelsHidden()
            }

            Text(tool.description.isEmpty ? "No description" : tool.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 6) {
                WorkspaceStatusBadge(title: tool.category, color: .indigo)
                WorkspaceStatusBadge(title: tool.inputScope.rawValue, color: .blue)
                WorkspaceStatusBadge(title: tool.outputStyle.rawValue, color: .purple)
                WorkspaceStatusBadge(title: tool.triggerMode.rawValue, color: .orange)
            }

            if !tool.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tool.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.14), in: Capsule())
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button("Edit") { editingTool = tool }
                    .buttonStyle(.bordered)
                Button("Duplicate") { duplicate(tool) }
                    .buttonStyle(.bordered)
                Button("Delete", role: .destructive) { manager.deleteIntegration(tool) }
                    .buttonStyle(.bordered)
                Spacer()
                Text(tool.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 6)
    }

    private func statChip(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func toggleEnabled(_ tool: IntegrationTool, to value: Bool) {
        var updated = tool
        updated.isEnabled = value
        manager.saveIntegration(updated)
    }

    private func duplicate(_ tool: IntegrationTool) {
        var copy = tool
        copy.id = UUID()
        copy.name = "\(tool.name) Copy"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        manager.saveIntegration(copy)
    }

    private func bulkSetEnabled(_ enabled: Bool) {
        for tool in manager.integrations {
            var updated = tool
            updated.isEnabled = enabled
            manager.saveIntegration(updated)
        }
    }

    private func deleteDisabled() {
        manager.integrations
            .filter { !$0.isEnabled }
            .forEach { manager.deleteIntegration($0) }
    }
}
