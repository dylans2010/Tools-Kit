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
                                project.requiredScopes.append(cap.rawValue)
                            } else {
                                project.requiredScopes.removeAll { $0 == cap.rawValue }
                            }
                        }
                    )) {
                        Label(cap.displayName, systemImage: cap.icon)
                    }
                }
            } header: {
                Text("API Scopes")
            }

            Section {
                Toggle("sdk.developer.noSandbox", isOn: Binding(
                    get: { project.requiredScopes.contains(SDKPermissionManager.noSandboxScope) },
                    set: { val in
                        if val {
                            project.requiredScopes.append(SDKPermissionManager.noSandboxScope)
                        } else {
                            project.requiredScopes.removeAll { $0 == SDKPermissionManager.noSandboxScope }
                        }
                    }
                ))
                .tint(.red)
            } header: {
                Text("Elevated Access")
            }
        }
        .navigationTitle("Permissions")
    }
}
