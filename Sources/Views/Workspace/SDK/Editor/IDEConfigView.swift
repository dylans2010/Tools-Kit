import SwiftUI

struct IDEConfigView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Project Configuration").font(.headline)
                            Text("Manage core project metadata and runtime settings.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SDKStatusPill(projectManager.currentProject?.status.rawValue.uppercased() ?? "DRAFT", color: .blue)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("General", subtitle: "Project identity and state", systemImage: "info.circle.fill")
            }

            Section("Metadata") {
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
            }

            Section {
                LabeledContent("Run configuration", value: state.selectedRunConfiguration?.name ?? "Default Sandbox")
                LabeledContent("Effective scopes", value: "\(state.effectiveScopes(for: projectManager.currentProject).count)")
                LabeledContent("Libraries", value: "\(state.libraries.count)")
                LabeledContent("Dependencies", value: "\(state.dependencies.count)")
                LabeledContent("Memory estimate", value: "\(state.memoryEstimateMB) MB")

                Button {
                    state.syncSDKGraphFromProject()
                    state.recalculateDiagnostics()
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Project With SDK Graph")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("SDK Runtime", subtitle: "Live execution environment status", systemImage: "cpu.fill")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Configuration")
    }
}
