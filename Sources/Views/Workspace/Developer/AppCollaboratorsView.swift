import SwiftUI

struct AppCollaboratorsView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingInvite = false
    @State private var inviteEmail = ""
    @State private var selectedRole = "Developer"

    var app: DeveloperApp? {
        appService.apps.first { $0.id == appID }
    }

    var body: some View {
        List {
            if let app = app {
                Section("Collaborators") {
                    if app.collaborators.isEmpty {
                        Text("No collaborators yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(app.collaborators) { collaborator in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(collaborator.name).font(.subheadline.bold())
                                    Text(collaborator.email).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(collaborator.role).font(.caption2.bold())
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1), in: Capsule())
                            }
                        }
                        .onDelete(perform: removeCollaborator)
                    }
                }
            }
        }
        .navigationTitle("Collaborators")
        .toolbar {
            Button { showingInvite = true } label: { Image(systemName: "person.badge.plus") }
        }
        .sheet(isPresented: $showingInvite) {
            inviteSheet
        }
    }

    private var inviteSheet: some View {
        NavigationStack {
            Form {
                TextField("Collaborator Email", text: $inviteEmail)
                Picker("Role", selection: $selectedRole) {
                    Text("Admin").tag("Admin")
                    Text("Developer").tag("Developer")
                    Text("Viewer").tag("Viewer")
                }
            }
            .navigationTitle("Invite Collaborator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingInvite = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        invite()
                    }
                    .disabled(inviteEmail.isEmpty)
                }
            }
        }
    }

    private func invite() {
        guard let appID = appID else { return }
        let collaborator = AppCollaborator(accountID: UUID(), name: inviteEmail.components(separatedBy: "@").first ?? "User", email: inviteEmail, role: selectedRole)
        Task {
            try? await appService.addCollaborator(appID: appID, collaborator: collaborator)
            await MainActor.run {
                showingInvite = false
                inviteEmail = ""
            }
        }
    }

    private func removeCollaborator(at offsets: IndexSet) {
        guard let app = app else { return }
        for index in offsets {
            let collaboratorID = app.collaborators[index].id
            Task {
                try? await appService.removeCollaborator(appID: app.id, collaboratorID: collaboratorID)
            }
        }
    }
}
