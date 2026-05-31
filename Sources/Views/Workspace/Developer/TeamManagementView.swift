import SwiftUI

struct TeamManagementView: View {
    @ObservedObject var orgService = OrganizationService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingAddMember = false
    @State private var memberEmail = ""
    @State private var selectedRole: TeamRole = .developer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workspace Team")
                        .font(.headline)
                    Text(orgService.organizationName).font(.headline)
                    Text("Manage cross-functional roles for your entire developer organization.").font(.caption).foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 0) {
                    Text("Members")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    HStack {
                        Text("Name").font(.caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Email").font(.caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Role").font(.caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    Divider()

                    if orgService.members.isEmpty {
                        EmptyStateView(icon: "person.2", title: "No Members", message: "Invite your teammates to start collaborating on projects.")
                            .padding()
                    } else {
                        ForEach(orgService.members, id: \.id) { member in
                            VStack(spacing: 0) {
                                HStack {
                                    Text(member.name).font(.subheadline.bold()).frame(maxWidth: .infinity, alignment: .leading)
                                    Text(member.email).font(.system(size: 9)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                                    roleBadge(TeamRole(rawValue: member.role.rawValue.lowercased()) ?? .developer)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal).padding(.vertical, 10)
                                Divider()
                            }
                        }
                    }
                }

                Button { showingAddMember = true } label: {
                    Label("Invite New Member", systemImage: "person.badge.plus.fill").font(.subheadline.bold())
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Team")
        .sheet(isPresented: $showingAddMember) { inviteMemberSheet }
    }

    private func roleBadge(_ role: TeamRole) -> some View {
        Text(role.rawValue.uppercased())
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(role.color.opacity(0.1))
            .foregroundStyle(role.color)
            .clipShape(Capsule())
    }

    private var inviteMemberSheet: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Email Address", text: $memberEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Access Control") {
                    Picker("Default Role", selection: $selectedRole) {
                        ForEach(TeamRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                }
            }
            .navigationTitle("Invite Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddMember = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        Task {
                            try? await orgService.inviteMember(email: memberEmail, role: selectedRole)
                            await MainActor.run {
                                showingAddMember = false
                                memberEmail = ""
                            }
                        }
                    }
                    .disabled(memberEmail.isEmpty || !memberEmail.contains("@"))
                }
            }
        }
    }

    private func removeMember(at offsets: IndexSet) {
        for index in offsets {
            let member = orgService.members[index]
            if let orgID = orgService.organizations.first?.id {
                Task { try? await orgService.removeMember(orgID: orgID, memberID: member.id) }
            }
        }
    }
}
