import SwiftUI

struct PluginBuildView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var version = "1.0.0"

    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Plugin Name", text: $name)
                TextField("Description", text: $description)
                TextField("Version", text: $version)
            }

            Section("Permissions & Capabilities") {
                Toggle("Access Notes", isOn: .constant(true))
                Toggle("Access Tasks", isOn: .constant(false))
                Toggle("Access GitHub", isOn: .constant(false))
            }

            Section {
                Button("Build & Register") {
                    // Logic to create PluginDefinition and save to DataStore
                    dismiss()
                }
                .disabled(name.isEmpty)
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Build Plugin")
    }
}
