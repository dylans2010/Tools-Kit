import SwiftUI

struct SDKDeploymentView: View {
    let project: SDKProject
    @StateObject private var manager = PluginManager.shared
    @State private var deploymentTarget: DeploymentTarget = .plugin
    @State private var isDeploying = false
    @State private var deployedPlugin: PluginDefinition?

    enum DeploymentTarget: String, CaseIterable {
        case plugin = "Plugin"
        case connector = "Connector"
    }

    var body: some View {
        List {
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
        }
    }

    private func deploy() {
        isDeploying = true
        let plugin = SDKExecutionBridge.shared.deployToPlugin(project: project)
        manager.savePlugin(plugin)
        deployedPlugin = plugin
        isDeploying = false
        SDKConsoleView.LogBus.shared.log("Project deployed as plugin: \(plugin.identifier)", type: .success)
    }
}
