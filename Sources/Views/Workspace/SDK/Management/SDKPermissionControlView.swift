

import SwiftUI

struct SDKPermissionControlView: View {
    @Binding var project: SDKProject

    var body: some View {
        List {
            Section {
                ForEach(PluginCapability.allCases) { cap in
                    Toggle(isOn: Binding(
                        get: { project.requiredScopes.contains(cap.rawValue) },
                        set: { isSelected in
                            if isSelected {
                                if !project.requiredScopes.contains(cap.rawValue) { project.requiredScopes.append(cap.rawValue) }
                            } else {
                                project.requiredScopes.removeAll { $0 == cap.rawValue }
                            }
                        }
                    )) {
                        Label(cap.displayName, systemImage: cap.icon)
                    }
                }
            } header: {
                Label("Workspace Capabilities", systemImage: "checklist")
            }

            Section {
                Toggle(isOn: Binding(
                    get: { project.requiredScopes.contains(SDKPermissionManager.noSandboxScope) },
                    set: { val in
                        if val {
                            if !project.requiredScopes.contains(SDKPermissionManager.noSandboxScope) { project.requiredScopes.append(SDKPermissionManager.noSandboxScope) }
                        } else {
                            project.requiredScopes.removeAll { $0 == SDKPermissionManager.noSandboxScope }
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No-Sandbox Access")
                        Text("Bypass kernel boundary restrictions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.red)
            } header: {
                Label("Elevated Privileges", systemImage: "exclamationmark.shield.fill")
            } footer: {
                Text("Enable only for internal system tools. This bypasses the default execution sandbox.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }
}
