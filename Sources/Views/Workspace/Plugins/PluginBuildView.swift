import SwiftUI

struct PluginBuildView: View {
    @StateObject private var manager = PluginManager.shared
    @Environment(\.dismiss) var dismiss

    // Identity
    @State private var name = ""
    @State private var identifierSuffix = ""
    @State private var description = ""
    @State private var icon = "puzzlepiece.extension"

    // Configuration
    @State private var selectedCapabilities: Set<PluginCapability> = []
    @State private var selectedActions: Set<PluginAction> = []
    @State private var selectedPermissions: Set<PluginPermission> = []

    // Code
    @State private var sourceCode = """
    export function onEvent(event, ctx) {
        // Your logic here
        return 'Plugin executed';
    }
    """

    // UI State
    @State private var showingIdLockedAlert = false
    @State private var isCreating = false

    var fullIdentifier: String {
        "com.ToolsKit.\(identifierSuffix)"
    }

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Plugin Name", text: $name)
                HStack {
                    Text("com.ToolsKit.")
                        .foregroundColor(.secondary)
                    TextField("Identifier", text: $identifierSuffix)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                TextField("Description", text: $description)

                Picker("Icon", selection: $icon) {
                    Image(systemName: "puzzlepiece.extension").tag("puzzlepiece.extension")
                    Image(systemName: "bolt.fill").tag("bolt.fill")
                    Image(systemName: "sparkles").tag("sparkles")
                    Image(systemName: "terminal.fill").tag("terminal.fill")
                    Image(systemName: "doc.text.fill").tag("doc.text.fill")
                }
            }

            Section("Capabilities") {
                FlowLayout(items: PluginCapability.allCases) { cap in
                    FilterChip(title: cap.rawValue, isSelected: selectedCapabilities.contains(cap)) {
                        if selectedCapabilities.contains(cap) {
                            selectedCapabilities.remove(cap)
                        } else {
                            selectedCapabilities.insert(cap)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Actions (Events)") {
                ForEach(PluginAction.allCases) { action in
                    Toggle(action.rawValue, isOn: Binding(
                        get: { selectedActions.contains(action) },
                        set: { isSelected in
                            if isSelected {
                                selectedActions.insert(action)
                                // Auto-select required capability
                                selectedCapabilities.insert(action.capability)
                            } else {
                                selectedActions.remove(action)
                            }
                        }
                    ))
                }
            }

            Section("Permissions") {
                ForEach(PluginPermission.allCases) { perm in
                    Toggle(perm.rawValue, isOn: Binding(
                        get: { selectedPermissions.contains(perm) },
                        set: { isSelected in
                            if isSelected {
                                selectedPermissions.insert(perm)
                            } else {
                                selectedPermissions.remove(perm)
                            }
                        }
                    ))
                }
            }

            Section("Logic (JavaScript)") {
                TextEditor(text: $sourceCode)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 200)
            }

            Section {
                Button(action: createPlugin) {
                    if isCreating {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Create Plugin")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || identifierSuffix.isEmpty || isCreating)
            }
        }
        .navigationTitle("New Plugin")
        .alert("Identifier Locked", isPresented: $showingIdLockedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The identifier \(fullIdentifier) will be locked after creation and cannot be changed.")
        }
    }

    private func createPlugin() {
        isCreating = true

        // In a real app, we might show the alert here first
        // showingIdLockedAlert = true

        _ = manager.createPlugin(
            name: name,
            identifier: fullIdentifier,
            description: description,
            icon: icon,
            capabilities: selectedCapabilities,
            actions: selectedActions,
            permissions: selectedPermissions,
            sourceCode: sourceCode
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCreating = false
            dismiss()
        }
    }
}

// Reusing FlowLayout if available, or providing a local simple version
struct FlowLayout<Item: Identifiable, Content: View>: View where Item: Hashable {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
            }
        }
    }
}
