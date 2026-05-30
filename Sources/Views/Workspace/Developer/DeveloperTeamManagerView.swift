import SwiftUI

struct DeveloperTeamManagerView: View {
    @ObservedObject var orgService = OrganizationService.shared
    @State private var showingAddMember = false
    @State private var newMemberName = ""
    @State private var newMemberEmail = ""
    @State private var selectedRole: OrgRole = .member
    @State private var selectedOrgID: UUID?

    var selectedOrg: DeveloperOrganization? {
        orgService.organizations.first { $0.id == selectedOrgID }
    }

    var body: some View {
        List {
            Section {
                Picker("Organization", selection: $selectedOrgID) {
                    Text("Select Organization").tag(Optional<UUID>.none)
                    ForEach(orgService.organizations) { org in
                        Text(org.name).tag(Optional(org.id))
                    }
                }
            }

            Section {
                if let org = selectedOrg {
                    if org.members.isEmpty {
                        Text("No team members yet. Invite collaborators to your project.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(org.members) { member in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(member.name).font(.subheadline.bold())
                                    Text(member.email).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Menu {
                                    ForEach(OrgRole.allCases, id: \.self) { role in
                                        Button(role.rawValue) {
                                            Task { try? await orgService.updateMemberRole(orgID: org.id, memberID: member.id, newRole: role) }
                                        }
                                    }
                                } label: {
                                    Text(member.role.rawValue).font(.caption2.bold())
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                                }
                            }
                        }
                        .onDelete(perform: deleteMember)
                    }
                } else {
                    Text("Select an organization to manage its team.").font(.caption).foregroundStyle(.secondary)
                }
            } header: {
                Text("Team Members")
            }
        }
        .navigationTitle("Team Management")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddMember = true } label: { Image(systemName: "person.badge.plus") }
                    .disabled(selectedOrgID == nil)
            }
        }
        .sheet(isPresented: $showingAddMember) {
            addMemberSheet
        }
    }

    private var addMemberSheet: some View {
        NavigationStack {
            Form {
                Section("Member Details") {
                    TextField("Name", text: $newMemberName)
                    TextField("Email", text: $newMemberEmail)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }

                Section("Role") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(OrgRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                }
            }
            .navigationTitle("Invite Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddMember = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") { addMember() }
                        .disabled(newMemberName.isEmpty || newMemberEmail.isEmpty)
                }
            }
        }
    }

    private func addMember() {
        guard let orgID = selectedOrgID else { return }
        Task {
            try? await orgService.addMember(orgID: orgID, email: newMemberEmail, role: selectedRole)
            await MainActor.run {
                showingAddMember = false
                newMemberName = ""
                newMemberEmail = ""
            }
        }
    }

    private func deleteMember(at offsets: IndexSet) {
        guard let orgID = selectedOrgID else { return }
        for index in offsets {
            if let member = selectedOrg?.members[index] {
                Task { try? await orgService.removeMember(orgID: orgID, memberID: member.id) }
            }
        }
    }
}
