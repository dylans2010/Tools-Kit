import SwiftUI

struct SDKTemplateListView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAddTemplate = false
    @State private var templateName = ""
    @State private var templateDescription = ""
    @State private var selectedCategory = "Core"

    let categories = ["Core", "UI", "Network", "Storage", "Analytics"]

    var body: some View {
        List {
            Section {
                Button(action: { showingAddTemplate = true }) {
                    Label("Create New Template", systemImage: "plus.square.fill")
                        .fontWeight(.semibold)
                }
            }

            ForEach(categories, id: \.self) { category in
                let filtered = store.sdkTemplates.filter { $0.category == category }
                if !filtered.isEmpty {
                    Section(category) {
                        ForEach(filtered) { template in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: template.icon)
                                        .foregroundStyle(.blue)
                                    Text(template.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(template.version)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            deleteTemplate(at: indexSet, from: filtered)
                        }
                    }
                }
            }

            if store.sdkTemplates.isEmpty {
                ContentUnavailableView("No SDK Templates", systemImage: "square.stack.3d.up.dottedline", description: Text("Create your first template to get started with standardized SDK development."))
            }
        }
        .navigationTitle("SDK Templates")
        .sheet(isPresented: $showingAddTemplate) {
            NavigationStack {
                Form {
                    Section("Template Identity") {
                        TextField("Name", text: $templateName)
                        TextField("Description", text: $templateDescription)
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                .navigationTitle("New Template")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddTemplate = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveTemplate()
                        }
                        .disabled(templateName.isEmpty)
                    }
                }
            }
        }
    }

    private func saveTemplate() {
        let newTemplate = SDKTemplate(
            name: templateName,
            description: templateDescription,
            category: selectedCategory,
            icon: "shippingbox.fill",
            language: "Swift",
            version: "1.0.0"
        )
        var updated = store.sdkTemplates
        updated.append(newTemplate)
        store.saveSDKTemplates(updated)

        templateName = ""
        templateDescription = ""
        showingAddTemplate = false
    }

    private func deleteTemplate(at offsets: IndexSet, from filtered: [SDKTemplate]) {
        let idsToDelete = offsets.map { filtered[$0].id }
        var updated = store.sdkTemplates
        updated.removeAll { idsToDelete.contains($0.id) }
        store.saveSDKTemplates(updated)
    }
}
