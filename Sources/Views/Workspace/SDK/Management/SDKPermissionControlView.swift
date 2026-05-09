/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Modernized capability toggles using native Label and semantic status icons.
 - Replaced manual Section headers with native system headers.
 - Standardized 'No-Sandbox' permission warning using semantic red coloring and descriptive footer.
 - strictly preserved all project scope binding and permission manager logic.
 - Improved visual consistency with other permission management screens.
 */

import SwiftUI

struct SDKPermissionControlView: View {
    @Binding var project: SDKProject

    var body: some View {
        List {
            Section("Workspace Capabilities") {
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
                Text("Elevated Privileges")
            } footer: {
                Text("Enable only for internal system tools. This bypasses the default execution sandbox.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }
}
