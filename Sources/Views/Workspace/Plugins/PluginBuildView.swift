import SwiftUI

struct PluginBuildView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = PluginManager.shared

    // Identity
    @State private var name = ""
    @State private var description = ""
    @State private var author = "Developer"
    @State private var version = "1.0.0"
    @State private var icon = "puzzlepiece"
    @State private var identifier = ""
    @State private var isIdentifierLocked = false

    // Capabilities & Actions
    @State private var selectedCapabilities: Set<PluginCapability> = []
    @State private var selectedActions: Set<PluginAction> = []

    // Logic
    @State private var sourceCode = """
export async function onEvent(event, ctx) {
  if (event.type === "note.created") {
    const summary = await ctx.ai.summarize(event.payload.content)
    await ctx.notes.updateNote(event.payload.id, summary)
  }
}
"""

    @State private var showingIdentifierLockAlert = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            identitySection
            capabilitiesSection
            actionsSection
            permissionsSummarySection
            logicEditorSection
            buildSection
        }
        .navigationTitle("Create Plugin")
        .alert("Identifier Locked", isPresented: $showingIdentifierLockAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The identifier 'com.ToolsKit.\(identifier)' cannot be changed after creation.")
        }
    }

    // MARK: - Sections

    private var identitySection: some View {
        Section("Plugin Identity") {
            TextField("Name", text: $name)
            TextField("Description", text: $description)
            TextField("Author", text: $author)
            TextField("Version", text: $version)

            HStack {
                Text("Identifier")
                Spacer()
                if isIdentifierLocked {
                    Text("com.ToolsKit.\(identifier)")
                        .foregroundColor(.secondary)
                } else {
                    Text("com.ToolsKit.")
                        .foregroundColor(.secondary)
                    TextField("unique-id", text: $identifier)
                        .multilineTextAlignment(.trailing)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .onTapGesture {
                if isIdentifierLocked { showingIdentifierLockAlert = true }
            }
        }
    }

    private var capabilitiesSection: some View {
        Section("Capabilities (System Access)") {
            ForEach(PluginCapability.allCases) { cap in
                Toggle(isOn: Binding(
                    get: { selectedCapabilities.contains(cap) },
                    set: { isSelected in
                        if isSelected {
                            selectedCapabilities.insert(cap)
                        } else {
                            selectedCapabilities.remove(cap)
                            // Remove dependent actions
                            selectedActions = selectedActions.filter { $0.parentCapability != cap }
                        }
                    }
                )) {
                    Label(cap.displayName, systemImage: cap.icon)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions (Event Subscriptions)") {
            if selectedCapabilities.isEmpty {
                Text("Select capabilities first").foregroundColor(.secondary).font(.caption)
            } else {
                ForEach(PluginAction.allCases.filter { selectedCapabilities.contains($0.parentCapability) }) { action in
                    Toggle(action.rawValue, isOn: Binding(
                        get: { selectedActions.contains(action) },
                        set: { isSelected in
                            if isSelected { selectedActions.insert(action) }
                            else { selectedActions.remove(action) }
                        }
                    ))
                }
            }
        }
    }

    private var permissionsSummarySection: some View {
        Section("Permissions Summary") {
            if selectedCapabilities.isEmpty {
                Text("No permissions requested").foregroundColor(.secondary).font(.caption)
            } else {
                ForEach(Array(selectedCapabilities), id: \.self) { cap in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cap.displayName).font(.subheadline.bold())
                        Text(PluginPermission(capability: cap).description)
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var logicEditorSection: some View {
        Section("Plugin Logic (JavaScript)") {
            TextEditor(text: $sourceCode)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

            Text("Access full PluginContext via 'ctx' object.")
                .font(.caption2).foregroundColor(.secondary)
        }
    }

    private var buildSection: some View {
        Section {
            if let error = errorMessage {
                Text(error).foregroundColor(.red).font(.caption)
            }

            Button(action: buildAndInstall) {
                Text("Build & Install Plugin")
                    .frame(maxWidth: .infinity)
                    .bold()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
    }

    // MARK: - Validation & Actions

    private var isValid: Bool {
        !name.isEmpty && !identifier.isEmpty && !selectedCapabilities.isEmpty && !selectedActions.isEmpty && !sourceCode.isEmpty
    }

    private func buildAndInstall() {
        // Validation engine
        if manager.installedPlugins.contains(where: { $0.identifier == "com.ToolsKit.\(identifier)" }) {
            errorMessage = "Identifier already in use."
            return
        }

        let newPlugin = PluginDefinition(
            id: UUID(),
            name: name,
            description: description,
            author: author,
            version: version,
            icon: icon,
            identifier: "com.ToolsKit.\(identifier)",
            isEnabled: true,
            isInstalled: true,
            installedAt: Date(),
            capabilities: Array(selectedCapabilities),
            actions: Array(selectedActions),
            sourceCode: sourceCode
        )

        manager.savePlugin(newPlugin)
        dismiss()
    }
}
