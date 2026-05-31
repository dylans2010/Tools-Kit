import SwiftUI

struct AppCollaboratorsView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var organizationService = OrganizationService.shared
    @State private var showingInvite = false
    @State private var inviteEmail = ""
    @State private var selectedRole = TeamRole.developer
    @State private var showingRoleEditor = false
    @State private var collaboratorToEdit: AppCollaborator?

    var app: DeveloperApp? {
        appService.apps.first { $0.id == appID }
    }

    var body: some View {
        List {
            if let app = app {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Access Control").font(.headline)
                        Text("Manage who can access and modify this project. Changes are logged in the security audit.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Collaborators") {
                    if app.collaborators.isEmpty {
                        EmptyStateView(icon: "person.2", title: "Solo Project", message: "Invite your team to collaborate on this app.")
                    } else {
                        ForEach(app.collaborators) { collaborator in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(Color.accentColor.opacity(0.1))
                                    Text(String(collaborator.name.prefix(1))).font(.subheadline.bold()).foregroundStyle(Color.accentColor)
                                }
                                .frame(width: 36, height: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(collaborator.name).font(.subheadline.bold())
                                    Text(collaborator.email).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    collaboratorToEdit = collaborator
                                    showingRoleEditor = true
                                } label: {
                                    Text(collaborator.role)
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                                        .foregroundStyle(Color.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: removeCollaborator)
                    }
                }

                Section("Organization Policy") {
                    HStack {
                        Image(systemName: "shield.checkered").foregroundStyle(.secondary)
                        Text("Inherit Org Roles").font(.caption)
                        Spacer()
                        Toggle("", isOn: .constant(true)).labelsHidden().disabled(true)
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
        .sheet(isPresented: $showingRoleEditor) {
            if let collab = collaboratorToEdit {
                RoleEditorView(collaborator: collab, appID: appID)
            }
        }
    }

    private var inviteSheet: some View {
        NavigationStack {
            Form {
                Section("Recipient") {
                    TextField("Email Address", text: $inviteEmail, prompt: Text("Email Address"))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Role Assignment") {
                    Picker("Access Level", selection: $selectedRole) {
                        ForEach(TeamRole.allCases, id: \.self) { role in
                            HStack {
                                Text(role.rawValue.capitalized)
                                Spacer()
                                Text(roleDescription(role)).font(.caption2).foregroundStyle(.secondary)
                            }
                            .tag(role)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Invite Team Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingInvite = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send Invite") {
                        invite()
                    }
                    .disabled(inviteEmail.isEmpty || !inviteEmail.contains("@"))
                }
            }
        }
    }

    private func roleDescription(_ role: TeamRole) -> String {
        switch role {
        case .owner: return "Full management & deletion"
        case .admin: return "Manage team & settings"
        case .developer: return "Manage builds & config"
        case .viewer: return "Read-only access"
        }
    }

    private func invite() {
        let newCollab = AppCollaborator(
            accountID: UUID(),
            name: inviteEmail.components(separatedBy: "@").first?.capitalized ?? "Developer",
            email: inviteEmail,
            role: selectedRole.rawValue.capitalized
        )
        Task {
            try? await appService.addCollaborator(appID: appID, collaborator: newCollab)
            await MainActor.run {
                showingInvite = false
                inviteEmail = ""
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

struct RoleEditorView: View {
    let collaborator: AppCollaborator
    let appID: UUID
    @Environment(\.dismiss) var dismiss
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedRole: TeamRole = .developer

    var body: some View {
        NavigationStack {
            Form {
                Section("User Info") {
                    LabeledContent("Name", value: collaborator.name)
                    LabeledContent("Email", value: collaborator.email)
                }

                Section("Modify Role") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(TeamRole.allCases, id: \.self) { role in
                            Text(role.rawValue.capitalized).tag(role)
                        }
                    }
                }
            }
            .navigationTitle("Edit Role")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateRole()
                    }
                }
            }
            .onAppear {
                if let role = TeamRole(rawValue: collaborator.role.lowercased()) {
                    selectedRole = role
                }
            }
        }
    }

    private func updateRole() {
        Task {
            // Functional update: remove then add with new role (or implement updateCollaborator in service)
            try? await appService.removeCollaborator(appID: appID, collaboratorID: collaborator.id)
            var updated = collaborator
            updated.role = selectedRole.rawValue.capitalized
            try? await appService.addCollaborator(appID: appID, collaborator: updated)
            await MainActor.run { dismiss() }
        }
    }
}
