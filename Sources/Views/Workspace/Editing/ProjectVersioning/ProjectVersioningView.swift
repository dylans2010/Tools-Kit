import SwiftUI

struct ProjectVersioningView: View {
    let project: EditingProject
    let spaceID: UUID
    @StateObject private var manager = ProjectVersioningManager.shared
    @State private var commitMessage = ""
    @State private var isCommitting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Project Versioning")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Branch: main").font(.caption).foregroundColor(.secondary)

                TextField("Commit message...", text: $commitMessage)
                    .textFieldStyle(.roundedBorder)

                Button(action: performCommit) {
                    if isCommitting {
                        ProgressView()
                    } else {
                        Text("Commit Changes")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(commitMessage.isEmpty || isCommitting)
            }

            Divider()

            Button(action: {}) {
                Label("Create Review Request", systemImage: "arrow.triangle.pull")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.workspaceSurface)
        .cornerRadius(12)
    }

    private func performCommit() {
        isCommitting = true
        Task {
            try? await manager.commitProjectState(project: project, spaceID: spaceID, branchID: UUID(), message: commitMessage)
            await MainActor.run {
                isCommitting = false
                commitMessage = ""
            }
        }
    }
}
