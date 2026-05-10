

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
                .lineLimit(3...5)

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
                Label("Project Identity", systemImage: "person.text.rectangle")
            }

            Section {
                LabeledContent("Config", value: state.selectedRunConfiguration?.name ?? "Default Sandbox")
                LabeledContent("Effective Scopes", value: "\(state.effectiveScopes(for: projectManager.currentProject).count)")
                LabeledContent("Memory Estimate", value: "\(state.memoryEstimateMB) MB")
            } header: {
                Label("Runtime Profile", systemImage: "cpu")
            }

            Section {
                LabeledContent("Libraries", value: "\(state.libraries.count)")
                LabeledContent("Dependencies", value: "\(state.dependencies.count)")

                Button {
                    state.syncSDKGraphFromProject()
                    state.recalculateDiagnostics()
                } label: {
                    Label("Sync Project With SDK Graph", systemImage: "arrow.triangle.2.circlepath")
                }
                .font(.subheadline.bold())
            } header: {
                Label("System Integration", systemImage: "gearshape.2")
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
    }
}
