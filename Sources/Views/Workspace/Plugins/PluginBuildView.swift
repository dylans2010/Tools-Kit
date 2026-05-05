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

    // Security Scopes (High-Risk)
    @State private var apiKey: String?
    @State private var privacyNote: String?
    @State private var dataUsageExplanation: String?
    @State private var retentionPolicy: String?

    // Logic
    @State private var sourceCode = """
export async function onEvent(event, ctx) {
  if (event.type === "note.created") {
    const summary = await ctx.ai.summarize(event.payload.content)
    await ctx.notes.updateNote(event.payload.id, summary)
  }
}
"""

    @State private var testEventPayload = """
{"type":"note.created","payload":{"id":"sample-id","content":"Draft note text"}}
"""
    @State private var simulatedBuildOutput: [String] = []

    @State private var showingIdentifierLockAlert = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            identitySection
            capabilitiesSection
            actionsSection
            securitySection
            permissionsSummarySection
            logicEditorSection
            validationSection
            buildSection
        }
        .navigationTitle("Create Plugin")
        .alert("Identifier Locked", isPresented: $showingIdentifierLockAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The identifier 'com.toolskit.\(identifier)' cannot be changed after creation.")
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
                    Text("com.toolskit.\(identifier)")
                        .foregroundColor(.secondary)
                } else {
                    Text("com.toolskit.")
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

    private var securitySection: some View {
        Section("Security & Scopes") {
            let highRiskSelected = selectedCapabilities.contains { $0.riskLevel == .high }

            if highRiskSelected {
                NavigationLink(destination: SecurityScopeApplicationView(plugin: Binding(
                    get: { dummyPluginForSecurity },
                    set: { updated in
                        self.apiKey = updated.apiKey
                        self.privacyNote = updated.privacyNote
                        self.dataUsageExplanation = updated.dataUsageExplanation
                        self.retentionPolicy = updated.retentionPolicy
                    }
                ))) {
                    HStack {
                        Label("High-Risk Security Gate", systemImage: "shield.fill")
                            .foregroundColor(.red)
                        Spacer()
                        if apiKey != nil && privacyNote != nil {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        }
                    }
                }
            } else {
                Text("No high-risk scopes selected.").font(.caption).foregroundColor(.secondary)
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
                        HStack {
                            Text(cap.displayName).font(.subheadline.bold())
                            Spacer()
                            riskPill(cap.riskLevel)
                        }
                        Text(cap.description)
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func riskPill(_ risk: RiskLevel) -> some View {
        Text(risk.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(riskColor(risk).opacity(0.1))
            .foregroundColor(riskColor(risk))
            .clipShape(Capsule())
    }

    private func riskColor(_ risk: RiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .orange
        case .high, .critical: return .red
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

    private var validationSection: some View {
        Section("Quick Validation") {
            LabeledContent("Identifier", value: "com.toolskit.\(identifier.isEmpty ? "<missing>" : identifier)")
            LabeledContent("Capabilities", value: "\(selectedCapabilities.count)")
            LabeledContent("Actions", value: "\(selectedActions.count)")

            TextEditor(text: $testEventPayload)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 96)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

            Button("Run Build Checks") {
                runLocalValidation()
            }
            .buttonStyle(.bordered)

            if !simulatedBuildOutput.isEmpty {
                ForEach(simulatedBuildOutput, id: \.self) { line in
                    Text(line)
                        .font(.caption.monospaced())
                        .foregroundStyle(line.contains("ERROR") ? .red : .secondary)
                }
            }
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
        let highRiskSelected = selectedCapabilities.contains { $0.riskLevel == .high }
        let securityValid = !highRiskSelected || (apiKey != nil && privacyNote != nil)

        return !name.isEmpty && !identifier.isEmpty && !selectedCapabilities.isEmpty && !selectedActions.isEmpty && !sourceCode.isEmpty && securityValid
    }

    private func buildAndInstall() {
        // Validation engine
        if manager.installedPlugins.contains(where: { $0.identifier == "com.toolskit.\(identifier)" }) {
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
            identifier: "com.toolskit.\(identifier)",
            isEnabled: true,
            isInstalled: true,
            installedAt: Date(),
            capabilities: Array(selectedCapabilities),
            actions: Array(selectedActions),
            sourceCode: sourceCode,
            apiKey: apiKey,
            privacyNote: privacyNote,
            dataUsageExplanation: dataUsageExplanation,
            retentionPolicy: retentionPolicy
        )

        manager.savePlugin(newPlugin)
        dismiss()
    }

    private func runLocalValidation() {
        var output: [String] = []
        output.append("• Checking plugin manifest...")

        if identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            output.append("ERROR: identifier is required")
        }

        if selectedCapabilities.isEmpty {
            output.append("ERROR: at least one capability is required")
        }

        let highRiskSelected = selectedCapabilities.contains { $0.riskLevel == .high }
        if highRiskSelected && (apiKey == nil || privacyNote == nil) {
            output.append("ERROR: high-risk scopes require API Key and Privacy Note")
        }

        if selectedActions.isEmpty {
            output.append("ERROR: at least one action is required")
        }

        if (try? JSONSerialization.jsonObject(with: Data(testEventPayload.utf8))) == nil {
            output.append("ERROR: test event payload is not valid JSON")
        } else {
            output.append("✓ test event payload JSON is valid")
        }

        if output.count == 1 {
            output.append("✓ ready to build")
        }

        simulatedBuildOutput = output
    }

    // Helper to interface with SecurityScopeApplicationView
    private var dummyPluginForSecurity: PluginDefinition {
        PluginDefinition(
            id: UUID(),
            name: name,
            description: description,
            author: author,
            version: version,
            icon: icon,
            identifier: "com.toolskit.\(identifier)",
            capabilities: Array(selectedCapabilities),
            actions: Array(selectedActions),
            sourceCode: sourceCode,
            apiKey: apiKey,
            privacyNote: privacyNote,
            dataUsageExplanation: dataUsageExplanation,
            retentionPolicy: retentionPolicy
        )
    }
}
