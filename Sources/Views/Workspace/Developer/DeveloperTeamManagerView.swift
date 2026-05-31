import SwiftUI

struct DeveloperTeamManagerView: View {
    @ObservedObject var organizationService = OrganizationService.shared
    @State private var selectedTab = 0
    @State private var showingAddMember = false
    @State private var showingAddTeam = false
    @State private var newTeamName = ""

    var body: some View {
        VStack(spacing: 0) {
            Picker("Team Management", selection: $selectedTab) {
                Text("Members").tag(0)
                Text("Roles").tag(1)
                Text("Teams").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                membersView
            } else if selectedTab == 1 {
                rolesView
            } else {
                teamsView
            }
        }
        .navigationTitle("Team Manager")
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar {
            if selectedTab == 0 {
                Button { showingAddMember = true } label: { Image(systemName: "person.badge.plus") }
            } else if selectedTab == 2 {
                Button { showingAddTeam = true } label: { Image(systemName: "plus.square.fill.on.square.fill") }
            }
        }
        .sheet(isPresented: $showingAddMember) {
            AddMemberSheet()
        }
        .sheet(isPresented: $showingAddTeam) {
            addTeamSheet
        }
    }

    private var membersView: some View {
        List {
            Section("Current Organization Members") {
                let allMembers = organizationService.organizations.flatMap { $0.members }
                if allMembers.isEmpty {
                    Text("No organization members found.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(allMembers) { member in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color.primary.opacity(0.05))
                                Text(String(member.name.prefix(1))).font(.subheadline.bold())
                            }
                            .frame(width: 40, height: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name).font(.subheadline.bold())
                                Text(member.email).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            roleBadge(member.role.rawValue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func roleBadge(_ role: String) -> some View {
        Text(role.uppercased()).font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.primary.opacity(0.05), in: Capsule())
            .foregroundStyle(.primary)
    }

    private var rolesView: some View {
        List {
            Section("Organization Roles") {
                ForEach(OrgRole.allCases, id: \.self) { role in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(role.rawValue).font(.subheadline.bold())
                            Spacer()
                            roleBadge(role.rawValue)
                        }
                        Text(roleDescription(role)).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func roleDescription(_ role: OrgRole) -> String {
        switch role {
        case .owner: return "Full administrative control of the organization and all assets."
        case .admin: return "Can manage team members, billing, and project settings."
        case .billing: return "Can manage invoices, payment methods, and subscriptions."
        case .member: return "Standard access to organization resources."
        }
    }

    private var teamsView: some View {
        List {
            Section("Project Teams") {
                let allTeams = organizationService.organizations.flatMap { $0.teams }
                if allTeams.isEmpty {
                    Text("No project teams configured. Create teams to manage bulk app permissions.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(allTeams) { team in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(team.name).font(.subheadline.bold())
                            Text("\(team.members.count) members • \(team.appAccessIDs.count) Apps").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var addTeamSheet: some View {
        NavigationStack {
            Form {
                Section("Team Identity") {
                    TextField("Team Name", text: $newTeamName)
                }
            }
            .navigationTitle("New Team")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddTeam = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if let orgID = organizationService.organizations.first?.id {
                            Task {
                                try? await organizationService.createTeam(orgID: orgID, name: newTeamName)
                                await MainActor.run {
                                    showingAddTeam = false
                                    newTeamName = ""
                                }
                            }
                        }
                    }
                    .disabled(newTeamName.isEmpty)
                }
            }
        }
    }
}

struct AddMemberSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var organizationService = OrganizationService.shared
    @State private var email = ""
    @State private var role: OrgRole = .member

    var body: some View {
        NavigationStack {
            Form {
                Section("Invite New Member") {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    Picker("Role", selection: $role) {
                        ForEach(OrgRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                }
            }
            .navigationTitle("Invite Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        if let orgID = organizationService.organizations.first?.id {
                            Task {
                                try? await organizationService.addMember(orgID: orgID, email: email, role: role)
                                await MainActor.run { dismiss() }
                            }
                        }
                    }
                    .disabled(email.isEmpty)
                }
            }
        }
    }
}
