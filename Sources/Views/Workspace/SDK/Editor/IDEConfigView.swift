import SwiftUI

struct IDEConfigView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared

    var body: some View {
        Form {
            Section {
                TextField("Name", text: Binding(
                    get: { projectManager.currentProject?.name ?? "" },
                    set: {
                        guard var project = projectManager.currentProject else { return }
                        project.name = $0
                        projectManager.updateProject(project)
                        state.syncSDKGraphFromProject(project)
                        state.recalculateDiagnostics()
                    }
                ))
                TextField("Description", text: Binding(
                    get: { projectManager.currentProject?.description ?? "" },
                    set: {
                        guard var project = projectManager.currentProject else { return }
                        project.description = $0
                        projectManager.updateProject(project)
                    }
                ), axis: .vertical)
                Picker("Status", selection: Binding(
                    get: { projectManager.currentProject?.status ?? .draft },
                    set: {
                        guard var project = projectManager.currentProject else { return }
                        project.status = $0
                        projectManager.updateProject(project)
                    }
                )) {
                    ForEach(SDKProject.ProjectStatus.allCases, id: \.self) { status in
                        Text(status.rawValue.capitalized).tag(status)
                    }
                }
            } header: {
                SDKSectionHeader("Project", subtitle: "Core identification", systemImage: "briefcase")
            }

            Section {
                LabeledContent("Run configuration", value: state.selectedRunConfiguration?.name ?? "Default Sandbox")
                LabeledContent("Effective scopes", value: "\(state.effectiveScopes(for: projectManager.currentProject).count)")
                LabeledContent("Libraries", value: "\(state.libraries.count)")
                LabeledContent("Dependencies", value: "\(state.dependencies.count)")
                LabeledContent("Memory estimate", value: "\(state.memoryEstimateMB) MB")

                Button("Sync Project With SDK Graph") {
                    state.syncSDKGraphFromProject()
                    state.recalculateDiagnostics()
                }
                .fontWeight(.medium)
            } header: {
                SDKSectionHeader("SDK Runtime", subtitle: "Configuration and state", systemImage: "cpu")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Configuration")
    }
}
