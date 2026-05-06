import SwiftUI

struct SDKScopeEditorView: View {
    @Binding var scopes: [PluginCapability]

    var body: some View {
        List {
            Section("Workspace Access") {
                scopeToggle(.notes)
                scopeToggle(.tasks)
                scopeToggle(.mail)
                scopeToggle(.calendar)
                scopeToggle(.files)
            }

            Section("Advanced Access") {
                scopeToggle(.workspaceFetchFullData)
                scopeToggle(.aiPersonaQuery)
                scopeToggle(.intelligenceGraphRead)
            }

            Section("Developer Tools") {
                scopeToggle(.sdkDeveloperNoSandbox)
                    .tint(.red)
            }
        }
        .navigationTitle("Scope Editor")
    }

    private func scopeToggle(_ cap: PluginCapability) -> some View {
        Toggle(cap.displayName, isOn: Binding(
            get: { scopes.contains(cap) },
            set: { isSelected in
                if isSelected {
                    if !scopes.contains(cap) { scopes.append(cap) }
                } else {
                    scopes.removeAll { $0 == cap }
                }
            }
        ))
    }
}
