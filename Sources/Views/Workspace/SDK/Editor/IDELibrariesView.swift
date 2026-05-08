import SwiftUI

struct IDELibrariesView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var editingLibrary: SDKLibraryDefinition?
    private let resolver = SDKLibraryVersionResolver()

    var categories: [String] {
        var cats = Set(state.libraries.map { $0.category })
        cats.insert("All")
        return cats.sorted()
    }

    var filteredLibraries: [SDKLibraryDefinition] {
        state.libraries.filter { library in
            let matchesSearch = searchText.isEmpty || library.name.localizedCaseInsensitiveContains(searchText) || library.description.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "All" || library.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Module Registry").font(.headline)
                            Text("Manage shared SDK modules and pipeline stages.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { editingLibrary = newLibrary() } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Search libraries...", text: $searchText)
                            .font(.subheadline)
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(categories, id: \.self) { category in
                                Button { selectedCategory = category } label: {
                                    Text(category)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == category ? Color.accentColor : Color.primary.opacity(0.05), in: Capsule())
                                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Libraries", subtitle: "Managed SDK execution units", systemImage: "books.vertical.fill")
            }

            Section {
                if filteredLibraries.isEmpty {
                    ContentUnavailableView("No Libraries Found", systemImage: "books.vertical", description: Text("Try adjusting your search or category filter."))
                        .padding(.vertical, 20)
                } else {
                    ForEach(filteredLibraries) { library in
                        Button { editingLibrary = library } label: {
                            libraryCard(library)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        let idsToDelete = offsets.map { filteredLibraries[$0].id }
                        state.libraries.removeAll { idsToDelete.contains($0.id) }
                        state.recalculateDiagnostics()
                    }
                }
            } header: {
                SDKSectionHeader("Inventory", subtitle: "Active system modules", alignment: .leading)
            }
        }
        .sheet(item: $editingLibrary) { library in
            NavigationStack {
                IDELibraryEditorSheet(library: library) { updated in
                    state.upsertLibrary(updated)
                    editingLibrary = nil
                }
                .navigationTitle(library.name.isEmpty ? "New Library" : library.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { editingLibrary = nil } } }
            }
            .presentationDetents([.large])
        }
        .navigationTitle("Libraries")
    }

    private func libraryCard(_ library: SDKLibraryDefinition) -> some View {
        SDKModernCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(library.name).font(.subheadline.bold())
                        Text("v\(library.version) • \(library.category)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                    }
                    Spacer()
                    SDKStatusPill(library.usageCount > 0 ? "Active" : "Idle", color: library.usageCount > 0 ? .green : .secondary)
                }

                if !library.description.isEmpty {
                    Text(library.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 16) {
                    metric("Calls", "\(library.usageCount)", icon: "phone.fill")
                    metric("Scopes", "\(library.linkedScopes.count)", icon: "lock.shield.fill")
                    metric("Exports", "\(library.exportedFunctions.count)", icon: "shippingbox.fill")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Function Exports").font(.system(size: 8, weight: .bold)).foregroundStyle(.tertiary).textCase(.uppercase)
                    FlowLayout(spacing: 4) {
                        ForEach(library.exportedFunctions, id: \.name) { export in
                            Text(export.name)
                                .font(.system(size: 9, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func metric(_ label: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8))
            Text("\(value) \(label)").font(.system(size: 9, weight: .semibold))
        }
        .foregroundStyle(.secondary)
    }

    private func newLibrary() -> SDKLibraryDefinition {
        SDKLibraryDefinition(
            name: "Library \(state.libraries.count + 1)",
            category: "General",
            description: "New SDK library module.",
            linkedScopes: ["workspace.files.read"],
            exportedFunctions: [SDKLibraryFunctionExport(name: "run", signature: "() -> Void")],
            pipelineStages: ["prepare", "execute", "publish"]
        )
    }
}

private struct IDELibraryEditorSheet: View {
    @State var library: SDKLibraryDefinition
    let onSave: (SDKLibraryDefinition) -> Void

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Library Name", text: $library.name)
                TextField("Version", text: $library.version)
                TextField("Category", text: $library.category)
                TextField("Description", text: $library.description, axis: .vertical)
            }
            Section("SDK Scope Bindings") {
                TextField("Linked scopes (comma separated)", text: arrayBinding(\.linkedScopes))
                    .font(.system(.caption, design: .monospaced))
            }
            Section("Exports") {
                TextField("Exported functions (comma separated)", text: Binding(
                    get: { library.exportedFunctions.map(\.name).joined(separator: ", ") },
                    set: { names in
                        library.exportedFunctions = split(names).map { SDKLibraryFunctionExport(name: $0, signature: "() -> Void") }
                    }
                ))
            }
            Section("Pipeline") {
                TextField("Pipeline stages", text: arrayBinding(\.pipelineStages))
                TextField("Dependencies", text: arrayBinding(\.dependencies))
            }
            Section {
                Button { onSave(library) } label: {
                    Text("Save Library")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(library.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func arrayBinding(_ keyPath: WritableKeyPath<SDKLibraryDefinition, [String]>) -> Binding<String> {
        Binding(
            get: { library[keyPath: keyPath].joined(separator: ", ") },
            set: { library[keyPath: keyPath] = split($0) }
        )
    }

    private func split(_ text: String) -> [String] {
        text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var width: CGFloat = 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0

        for size in sizes {
            if x + size.width > (proposal.width ?? .infinity) {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
            width = max(width, x)
            height = max(height, y + maxHeight)
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0

        for (index, size) in sizes.enumerated() {
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            subviews[index].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}
