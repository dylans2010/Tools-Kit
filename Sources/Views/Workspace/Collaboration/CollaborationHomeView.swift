import SwiftUI

struct CollaborationHomeView: View {
    @StateObject private var manager = CollaborationManager.shared
    @State private var showingCreateSpace = false

    var body: some View {
        List {
            Section("Your Spaces") {
                if manager.spaces.isEmpty {
                    Text("No collaboration spaces yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(manager.spaces) { space in
                        NavigationLink(destination: SpaceDashboardView(spaceID: space.id)) {
                            Label(space.name, systemImage: space.icon)
                        }
                    }
                }
            }

            Section("Platform Modules") {
                NavigationLink("Pull Request Hub") {
                    PullRequestHubView(spaceID: manager.spaces.first?.id ?? UUID())
                }
                NavigationLink("Command Center") {
                    WorkspaceCommandCenterView()
                }
            }
        }
        .navigationTitle("Collaboration")
        .toolbar {
            Button(action: { showingCreateSpace = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingCreateSpace) {
            CreateSpaceView()
        }
    }
}

struct CreateSpaceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var visibility: SpaceVisibility = .privateSpace

    var body: some View {
        NavigationStack {
            Form {
                Section("Information") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                }

                Section("Privacy") {
                    Picker("Visibility", selection: $visibility) {
                        Text("Private").tag(SpaceVisibility.privateSpace)
                        Text("Shared").tag(SpaceVisibility.shared)
                        Text("Public").tag(SpaceVisibility.publicSpace)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Space")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let _ = CollaborationManager.shared.createSpace(
                            name: name,
                            description: description,
                            icon: "folder.fill.badge.person.crop",
                            visibility: visibility
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
