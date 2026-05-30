import SwiftUI

struct AppCollaboratorsView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingInvite = false
    @State private var inviteEmail = ""
    @State private var inviteName = ""
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
                Section("Invitation Details") {
                    TextField("Name", text: $inviteName)
                    TextField("Collaborator Email", text: $inviteEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    Picker("Role", selection: $selectedRole) {
                        Text("Admin").tag("Admin")
                        Text("Developer").tag("Developer")
                        Text("Viewer").tag("Viewer")
                    }
                }
            }
            .navigationTitle("Invite Collaborator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingInvite = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        invite()
                    }
                    .disabled(inviteEmail.isEmpty || inviteName.isEmpty)
                }
            }
        }
    }

    private func invite() {
        let collab = AppCollaborator(accountID: UUID(), name: inviteName, email: inviteEmail, role: selectedRole)
        Task {
            try? await appService.addCollaborator(appID: appID, collaborator: collab)
            await MainActor.run {
                showingInvite = false
                inviteEmail = ""
                inviteName = ""
            }
        }
    }

    private func removeCollaborator(at offsets: IndexSet) {
        guard let app = app else { return }
        for index in offsets {
            let collab = app.collaborators[index]
            Task {
                try? await appService.removeCollaborator(appID: appID, collaboratorID: collab.id)
            }
        }
    }
}
