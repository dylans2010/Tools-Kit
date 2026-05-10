

import SwiftUI

struct SDKDeploymentView: View {
    let project: SDKProject
    @StateObject private var manager = PluginManager.shared
    @State private var deploymentTarget: DeploymentTarget = .plugin
    @State private var isDeploying = false
    @State private var deployedPlugin: PluginDefinition?
    @State private var errorMessage: String?

    enum DeploymentTarget: String, CaseIterable {
        case plugin = "Plugin", connector = "Connector"
    }

    var body: some View {
        List {
            Section("Project Metadata") {
                LabeledContent("Name", value: project.name)
                LabeledContent("Health", value: project.healthStatus.rawValue.capitalized)
                LabeledContent("Scopes", value: "\(project.enabledScopes.count)")
            }

            Section("Deployment Configuration") {
                Picker("Target Platform", selection: $deploymentTarget) {
                    ForEach(DeploymentTarget.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }

            Section {
                Button(action: deploy) {
                    HStack {
                        if isDeploying { ProgressView().controlSize(.small) }
                        Text("Deploy to Workspace").bold()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDeploying)
            }

            if let plugin = deployedPlugin {
                Section("Active Deployment") {
                    Label("Successfully deployed", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    LabeledContent("Identifier") {
                        Text(plugin.identifier).font(.caption.monospaced())
                    }
                }
            }

            if let error = errorMessage {
                Section("Error") {
                    Label(error, systemImage: "exclamationmark.octagon.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Deploy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deploy() {
        isDeploying = true
        errorMessage = nil
        let legacy = SDKProjectLegacy(id: project.id, name: project.name, sourceCode: project.sourceCode, requiredScopes: project.requiredScopes, status: .idle)
        let plugin = SDKExecutionBridge.shared.deployToPlugin(project: legacy)
        manager.savePlugin(plugin)
        deployedPlugin = plugin
        isDeploying = false
        SDKLogStore.shared.log("Project deployed: \(plugin.identifier)", source: "SDKDeploymentView", level: .info)
    }
}
