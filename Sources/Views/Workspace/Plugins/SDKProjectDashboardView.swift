import SwiftUI

struct SDKProjectDashboardView: View {
    @StateObject private var stateManager = SDKStateManager.shared
    @Binding var selectedProject: SDKProject?

    var body: some View {
        List {
            Section("My SDK Projects") {
                if stateManager.savedProjects.isEmpty {
                    Text("No projects yet. Create your first SDK tool.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(stateManager.savedProjects) { project in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(project.name).font(.headline)
                                Text(project.status.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(project.status == .running ? .green : .secondary)
                            }
                            Spacer()
                            Button("Open") {
                                selectedProject = project
                            }
                        }
                    }
                }
            }

            Section {
                Button(action: createNewProject) {
                    Label("New SDK Project", systemImage: "plus")
                }
            }
        }
    }

    private func createNewProject() {
        let new = SDKProject(
            id: UUID(),
            name: "New Project \(stateManager.savedProjects.count + 1)",
            sourceCode: "// SDK Code here\nprint('Hello WorkspaceAPI');",
            requiredScopes: [],
            status: .idle
        )
        stateManager.saveProject(new)
        selectedProject = new
    }
}
