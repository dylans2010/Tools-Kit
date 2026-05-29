import SwiftUI

struct CollabPermissionsView: View {
    @State private var members: [TeamMember] = []
    @State private var showingAddMember = false
    @State private var searchText = ""

    fileprivate var filteredMembers: [TeamMember] {
        if searchText.isEmpty { return members }
        return members.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.email.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            Section("Team Overview") {
                HStack(spacing: 16) {
                    roleCard(role: .owner, count: members.filter({ $0.role == .owner }).count)
                    roleCard(role: .admin, count: members.filter({ $0.role == .admin }).count)
                    roleCard(role: .developer, count: members.filter({ $0.role == .developer }).count)
                    roleCard(role: .viewer, count: members.filter({ $0.role == .viewer }).count)
                }
            }

            Section("Members (\(filteredMembers.count))") {
                ForEach(filteredMembers) { member in
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(member.role.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name)
                                .font(.subheadline.bold())
                            Text(member.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu {
                            ForEach(TeamRole.allCases, id: \.self) { role in
                                Button {
                                    updateRole(memberID: member.id, to: role)
                                } label: {
                                    HStack {
                                        Text(role.rawValue.capitalized)
                                        if member.role == role {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            Divider()
                            Button("Remove", role: .destructive) {
                                members.removeAll { $0.id == member.id }
                            }
                        } label: {
                            Text(member.role.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(member.role.color.opacity(0.15))
                                .foregroundStyle(member.role.color)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Section("Permissions Matrix") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Permission").font(.caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Own").font(.caption.bold()).frame(width: 40)
                        Text("Adm").font(.caption.bold()).frame(width: 40)
                        Text("Dev").font(.caption.bold()).frame(width: 40)
                        Text("View").font(.caption.bold()).frame(width: 40)
                    }
                    Divider()
                    permissionRow("View workspace", owner: true, admin: true, developer: true, viewer: true)
                    permissionRow("Edit content", owner: true, admin: true, developer: true, viewer: false)
                    permissionRow("Manage plugins", owner: true, admin: true, developer: true, viewer: false)
                    permissionRow("Manage members", owner: true, admin: true, developer: false, viewer: false)
                    permissionRow("Delete workspace", owner: true, admin: true, developer: false, viewer: false)
                    permissionRow("Manage billing", owner: true, admin: true, developer: false, viewer: false)
                }
            }
        }
        .navigationTitle("Permissions")
        .searchable(text: $searchText, prompt: "Search members")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddMember = true } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .task { loadMembers() }
    }

    private func roleCard(role: TeamRole, count: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(count)").font(.title2.bold()).foregroundStyle(role.color)
            Text(role.rawValue.capitalized + "s").font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func permissionRow(_ permission: String, owner: Bool, admin: Bool, developer: Bool, viewer: Bool) -> some View {
        HStack {
            Text(permission).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: owner ? "checkmark.circle.fill" : "xmark.circle").foregroundStyle(owner ? .green : .red).frame(width: 40)
            Image(systemName: admin ? "checkmark.circle.fill" : "xmark.circle").foregroundStyle(admin ? .green : .red).frame(width: 40)
            Image(systemName: developer ? "checkmark.circle.fill" : "xmark.circle").foregroundStyle(developer ? .green : .red).frame(width: 40)
            Image(systemName: viewer ? "checkmark.circle.fill" : "xmark.circle").foregroundStyle(viewer ? .green : .red).frame(width: 40)
        }
    }

    private func updateRole(memberID: UUID, to role: TeamRole) {
        if let index = members.firstIndex(where: { $0.id == memberID }) {
            members[index].role = role
        }
    }

    private func loadMembers() {
        // Team members are managed by the workspace owner; start empty until members are added.
    }
}
