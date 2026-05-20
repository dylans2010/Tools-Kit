
import SwiftUI

struct PluginSecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = SDKPluginManager.shared

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
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)

                Section("Permissions") {
                    ForEach($permissions) { $perm in
                        Toggle(isOn: $perm.isEnabled) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(perm.name).font(.subheadline.bold())
                                    Text(perm.description).font(.caption2).foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: perm.icon).foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }

                Section("Runtime Policy") {
                    NavigationLink {
                        List {
                            Section("Isolation Level") {
                                Text("Standard Sandbox").font(.subheadline).bold()
                                Text("Plugins execute in an isolated JavaScriptCore environment with no direct filesystem access.").font(.caption).foregroundStyle(.secondary)
                            }
                        }.navigationTitle("Sandbox Settings")
                    } label: {
                        Label("Sandbox Execution Mode", systemImage: "square.dashed.inset.filled")
                    }

                    NavigationLink {
                        List {
                            Section("Recent Events") {
                                ContentUnavailableView("No Logs", systemImage: "list.bullet.rectangle", description: Text("Security audit logs will appear here after plugin activity."))
                            }
                        }.navigationTitle("Audit Logs")
                    } label: {
                        Label("Security Audit Logs", systemImage: "clock.badge.checkmark")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
