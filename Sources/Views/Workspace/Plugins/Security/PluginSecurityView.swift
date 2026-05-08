import SwiftUI

struct PluginSecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = PluginManager.shared

    @State private var permissions: [PluginSecurityPermission] = [
        PluginSecurityPermission(name: "Network Access", description: "Allow plugins to make external API calls.", isEnabled: true, icon: "network"),
        PluginSecurityPermission(name: "File Storage", description: "Allow plugins to read and write to workspace files.", isEnabled: false, icon: "folder.fill"),
        PluginSecurityPermission(name: "Notifications", description: "Allow plugins to send system-level alerts.", isEnabled: true, icon: "bell.fill"),
        PluginSecurityPermission(name: "AI Context", description: "Allow plugins to access conversation history for reasoning.", isEnabled: true, icon: "brain"),
        PluginSecurityPermission(name: "Contacts", description: "Allow access to workspace member directory.", isEnabled: false, icon: "person.2.fill")
    ]

    struct PluginSecurityPermission: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        var isEnabled: Bool
        let icon: String
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Manage global security defaults for all installed plugins. Individual overrides can be set in plugin details.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    ForEach($permissions) { $perm in
                        Toggle(isOn: $perm.isEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: perm.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(perm.name).font(.subheadline.bold())
                                    Text(perm.description).font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Permissions")
                }

                Section {
                    NavigationLink("Sandbox Execution Mode") {
                        Text("Sandbox Settings")
                    }
                    NavigationLink("Security Audit Logs") {
                        Text("Audit Logs")
                    }
                } header: {
                    Text("Advanced")
                }
            }
            .navigationTitle("Plugin Security")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
