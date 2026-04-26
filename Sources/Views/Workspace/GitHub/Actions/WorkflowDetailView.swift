import SwiftUI

struct WorkflowDetailView: View {
    let owner: String
    let repo: String
    let workflow: GitHubWorkflow
    let lastRun: GitHubWorkflowRun?

    @StateObject private var manager = WorkflowManager()
    @State private var showRunSheet = false
    @State private var yaml = ""
    @State private var editable = false
    @State private var ref = "main"
    @State private var statusMessage = ""
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section("Workflow") {
                Text(workflow.name)
                Text(workflow.path).font(.caption)
                Text("Created: \(workflow.createdAt.formatted())")
                Text("Updated: \(workflow.updatedAt.formatted())")
            }

            Section("Context") {
                Text("Repository: \(owner)/\(repo)")
                TextField("Ref", text: $ref)
                if let lastRun {
                    Text("Last run branch: \(lastRun.headBranch)")
                    Text("Last commit: \(lastRun.headSHA)").font(.caption)
                }
            }

            Section("Execution") {
                Button("Run Workflow") { showRunSheet = true }
                NavigationLink("View Runs") {
                    WorkflowRunView(owner: owner, repo: repo, workflowID: workflow.id)
                }
                Button(workflow.state == "active" ? "Disable Workflow" : "Enable Workflow") {
                    Task {
                        let ok = await manager.setWorkflowState(workflowID: workflow.id, owner: owner, repo: repo, enabled: workflow.state != "active")
                        statusMessage = ok ? "Workflow state updated successfully." : (manager.lastError ?? "Failed to update workflow state.")
                    }
                }
                Button("Open in GitHub") {
                    openURL(workflow.htmlURL)
                }
            }

            Section("YAML") {
                Toggle("Editable", isOn: $editable)
                TextEditor(text: $yaml)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 240)
                    .disabled(!editable)
                Button("Reload YAML") {
                    Task {
                        do {
                            yaml = try await manager.loadYAML(owner: owner, repo: repo, workflowPath: workflow.path, ref: ref)
                            statusMessage = "Workflow YAML refreshed."
                        } catch {
                            statusMessage = "Failed to load YAML: \(error.localizedDescription)"
                        }
                    }
                }
            }
            if !statusMessage.isEmpty {
                Section("Status") {
                    Text(statusMessage).font(.caption)
                }
            }
        }
        .navigationTitle(workflow.name)
        .sheet(isPresented: $showRunSheet) {
            RunWorkflowView(owner: owner, repo: repo, workflowID: "\(workflow.id)")
        }
        .task {
            do {
                yaml = try await manager.loadYAML(owner: owner, repo: repo, workflowPath: workflow.path, ref: ref)
            } catch {
                yaml = "Failed to load YAML: \(error.localizedDescription)"
            }
        }
    }
}
