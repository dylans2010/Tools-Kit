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
                    roleCard(role: .admin, count: members.count(where: { $0.role == .admin }))
                    roleCard(role: .editor, count: members.count(where: { $0.role == .editor }))
                    roleCard(role: .viewer, count: members.count(where: { $0.role == .viewer }))
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
                            ForEach(MemberRole.allCases, id: \.self) { role in
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
                    permissionRow("View workspace", admin: true, editor: true, viewer: true)
                    permissionRow("Edit content", admin: true, editor: true, viewer: false)
                    permissionRow("Manage plugins", admin: true, editor: true, viewer: false)
                    permissionRow("Manage members", admin: true, editor: false, viewer: false)
                    permissionRow("Delete workspace", admin: true, editor: false, viewer: false)
                    permissionRow("Manage billing", admin: true, editor: false, viewer: false)
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

    private func roleCard(role: MemberRole, count: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(count)").font(.title2.bold()).foregroundStyle(role.color)
            Text(role.rawValue.capitalized + "s").font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func permissionRow(_ permission: String, admin: Bool, editor: Bool, viewer: Bool) -> some View {
        HStack {
            Text(permission).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: admin ? "checkmark.circle.fill" : "xmark.circle").foregroundStyle(admin ? .green : .red).frame(width: 50)
            Image(systemName: editor ? "checkmark.circle.fill" : "xmark.circle").foregroundStyle(editor ? .green : .red).frame(width: 50)
            Image(systemName: viewer ? "checkmark.circle.fill" : "xmark.circle").foregroundStyle(viewer ? .green : .red).frame(width: 50)
        }
    }

    private func updateRole(memberID: UUID, to role: MemberRole) {
        if let index = members.firstIndex(where: { $0.id == memberID }) {
            members[index].role = role
        }
    }

    private func loadMembers() {
        // Team members are managed by the workspace owner; start empty until members are added.
    }
}

private struct TeamMember: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    var role: MemberRole
}

private enum MemberRole: String, CaseIterable {
    case admin, editor, viewer

    var color: Color {
        switch self {
        case .admin: return .red
        case .editor: return .blue
        case .viewer: return .green
        }
    }
}
