import SwiftUI

struct TeamManagementView: View {
    @ObservedObject var orgService = OrganizationService.shared
    @State private var showingAddMember = false
    @State private var memberEmail = ""
    @State private var selectedRole: OrgRole = .member

    var body: some View {
        List {
            if orgService.organizations.isEmpty {
                EmptyStateView(icon: "building.2", title: "No Organizations", message: "No organizations found.")
            } else {
                ForEach(orgService.organizations) { org in
                    Section(org.name) {
                        ForEach(org.members) { member in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(member.name).font(.subheadline.bold())
                                    Text(member.email).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(member.role.rawValue).font(.caption2.bold())
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1), in: Capsule())
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                let member = org.members[index]
                                Task { try? await orgService.removeMember(orgID: org.id, memberID: member.id) }
                            }
                        }

                        Button {
                            showingAddMember = true
                            // In real app, would set targetOrgID
                        } label: {
                            Label("Invite Member", systemImage: "person.badge.plus")
                        }
                    }
                }
            }
        }
        .navigationTitle("Team Management")
        .sheet(isPresented: $showingAddMember) {
            inviteMemberSheet
        }
    }

    private var inviteMemberSheet: some View {
        NavigationStack {
            Form {
                TextField("Email Address", text: $memberEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                Picker("Role", selection: $selectedRole) {
                    ForEach(OrgRole.allCases, id: \.self) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
            }
            .navigationTitle("Invite to Organization")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddMember = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send Invite") {
                        if let firstOrg = orgService.organizations.first {
                            Task {
                                try? await orgService.addMember(orgID: firstOrg.id, email: memberEmail, role: selectedRole)
                                await MainActor.run {
                                    memberEmail = ""
                                    showingAddMember = false
                                }
                            }
                        }
                    }
                    .disabled(memberEmail.isEmpty)
                }
            }
        }
    }
}
