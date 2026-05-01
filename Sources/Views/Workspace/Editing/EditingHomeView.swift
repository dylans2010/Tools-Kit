import SwiftUI

struct EditingHomeView: View {
    @StateObject private var manager = EditingManager.shared
    @State private var showingCreateProject = false

    var body: some View {
        List {
            Section("Recent Projects") {
                if manager.projects.isEmpty {
                    Text("No projects yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(manager.projects) { project in
                        NavigationLink(destination: FullEditorView(projectID: project.id)) {
                            HStack {
                                Image(systemName: "photo")
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)

                                VStack(alignment: .leading) {
                                    Text(project.name)
                                        .font(.headline)
                                    Text("Last edited: \(project.updatedAt, style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Media Editing")
        .toolbar {
            Button(action: { showingCreateProject = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView()
        }
    }
}

struct CreateProjectView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Project Name", text: $name)
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let _ = EditingManager.shared.createProject(name: name, canvasSize: CGSize(width: 1080, height: 1080))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
