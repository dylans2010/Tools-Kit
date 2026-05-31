import SwiftUI

struct DeveloperTeamManagerView: View {
    @ObservedObject var organizationService = OrganizationService.shared
    @State private var selectedTab = 0
    @State private var showingAddMember = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Team Management", selection: $selectedTab) {
                Text("Members").tag(0)
                Text("Roles").tag(1)
                Text("Groups").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                membersView
            } else if selectedTab == 1 {
                rolesView
            } else {
                groupsView
            }
        }
        .navigationTitle("Team Manager")
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar {
            if selectedTab == 0 {
                Button { showingAddMember = true } label: { Image(systemName: "person.badge.plus") }
            }
        }
        .sheet(isPresented: $showingAddMember) {
            AddTeamMemberSheet()
        }
    }

    private var membersView: some View {
        List {
            Section("Current Members") {
                if organizationService.members.isEmpty {
                    Text("No team members found.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(organizationService.members) { member in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(member.role.color.opacity(0.1))
                                Text(String(member.name.prefix(1))).font(.subheadline.bold()).foregroundStyle(member.role.color)
                            }
                            .frame(width: 40, height: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name).font(.subheadline.bold())
                                Text(member.email).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            roleBadge(member.role)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: organizationService.removeMember)
                }
            }
        }
    }

    private func roleBadge(_ role: TeamRole) -> some View {
        Text(role.rawValue.uppercased()).font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(role.color.opacity(0.1), in: Capsule())
            .foregroundStyle(role.color)
    }

    private var rolesView: some View {
        List {
            Section("Role Definitions") {
                ForEach(TeamRole.allCases, id: \.self) { role in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(role.rawValue.capitalized).font(.subheadline.bold())
                            Spacer()
                            roleBadge(role)
                        }
                        Text(roleDescription(role)).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func roleDescription(_ role: TeamRole) -> String {
        switch role {
        case .owner: return "Full administrative control of the organization and all assets."
        case .admin: return "Can manage team members, billing, and project settings."
        case .developer: return "Can manage builds, environments, and source code."
        case .viewer: return "Read-only access to all dashboards and reports."
        }
    }

    private var groupsView: some View {
        List {
            Section("Access Groups") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Core Engineering").font(.subheadline.bold())
                    Text("12 members • All Projects").font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quality Assurance").font(.subheadline.bold())
                    Text("4 members • 2 Projects").font(.caption).foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    // add group
                } label: {
                    Label("Create Group", systemImage: "person.3.fill")
                }
            }
        }
    }
}

struct AddTeamMemberSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var organizationService = OrganizationService.shared
    @State private var name = ""
    @State private var email = ""
    @State private var role: TeamRole = .developer

    var body: some View {
        NavigationStack {
            Form {
                Section("Member Identity") {
                    TextField("Full Name", text: $name)
                    TextField("Email Address", text: $email).keyboardType(.emailAddress).autocapitalization(.none)
                }

                Section("Role Assignment") {
                    Picker("Role", selection: $role) {
                        ForEach(TeamRole.allCases, id: \.self) { role in
                            Text(role.rawValue.capitalized).tag(role)
                        }
                    }
                }
            }
            .navigationTitle("Invite Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        let newMember = TeamMember(id: UUID(), name: name, email: email, role: role, joinedAt: Date())
                        organizationService.addMember(newMember)
                        dismiss()
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
}
