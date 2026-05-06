import SwiftUI

struct SDKDeploymentView: View {
    let project: SDKProject
    @StateObject private var manager = PluginManager.shared
    @State private var deploymentTarget: DeploymentTarget = .plugin
    @State private var isDeploying = false
    @State private var deployedPlugin: PluginDefinition?
    @State private var errorMessage: String?

    enum DeploymentTarget: String, CaseIterable {
        case plugin = "Plugin"
        case connector = "Connector"
    }

    var body: some View {
        List {
            Section("Project Info") {
                LabeledContent("Name", value: project.name)
                LabeledContent("Health", value: project.healthStatus.rawValue.capitalized)
                LabeledContent("Scopes", value: "\(project.enabledScopes.count)")
            }

            Section("Deployment Settings") {
                Picker("Target", selection: $deploymentTarget) {
                    ForEach(DeploymentTarget.allCases, id: \.self) { target in
                        Text(target.rawValue).tag(target)
                    }
                }
            }

            Section("Immediate Action") {
                Button(action: deploy) {
                    if isDeploying {
                        ProgressView().padding(.trailing, 8)
                    }
                    Text("Deploy Now")
                        .bold()
                }
                .disabled(isDeploying)
                .frame(maxWidth: .infinity)
            }

            if let plugin = deployedPlugin {
                Section("Live Plugin Info") {
                    Label("Active", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("ID: \(plugin.identifier)")
                        .font(.system(.caption, design: .monospaced))
                }
            }

            if let error = errorMessage {
                Section("Error") {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
        }
        .navigationTitle("Deploy")
    }

    private func deploy() {
        isDeploying = true
        errorMessage = nil

        let legacyProject = SDKProjectLegacy(
            id: project.id,
            name: project.name,
            sourceCode: project.sourceCode,
            requiredScopes: project.requiredScopes,
            status: .idle
        )

        let plugin = SDKExecutionBridge.shared.deployToPlugin(project: legacyProject)
        manager.savePlugin(plugin)
        deployedPlugin = plugin
        isDeploying = false
        SDKLogStore.shared.log("Project deployed as plugin: \(plugin.identifier)", source: "SDKDeploymentView", level: .info)
        SDKConsoleView.LogBus.shared.log("Project deployed as plugin: \(plugin.identifier)", type: .success)
    }
}
