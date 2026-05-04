import SwiftUI

struct PluginBuildView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = PluginManager.shared

    @State private var name = ""
    @State private var description = ""
    @State private var version = "1.0.0"
    @State private var selectedCategory: PluginDefinition.PluginCategory = .utility

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Plugin Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Version", text: $version)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(PluginDefinition.PluginCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }

                Section("Capabilities") {
                    Text("This plugin will have access to the Workspace Event Bus and Data Store within sandbox boundaries.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button("Build & Install") {
                        createNewPlugin()
                    }
                    .disabled(name.isEmpty)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Build Plugin")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func createNewPlugin() {
        let newPlugin = PluginDefinition(
            id: UUID(),
            name: name,
            description: description,
            version: version,
            author: "Local Developer",
            category: selectedCategory,
            icon: "hammer.fill",
            isEnabled: true,
            isInstalled: true,
            commands: [],
            targetSystems: [.global],
            installedAt: Date()
        )

        manager.installCustomPlugin(newPlugin)
        dismiss()
    }
}
