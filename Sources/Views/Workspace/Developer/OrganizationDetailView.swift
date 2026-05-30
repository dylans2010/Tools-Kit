import SwiftUI

struct OrganizationDetailView: View {
    let organization: DeveloperOrganization
    @ObservedObject var orgService = OrganizationService.shared

    var body: some View {
        List {
            Section("Overview") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(organization.name).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Owner")
                    Spacer()
                    Text(organization.ownerID.uuidString.prefix(8)).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                }
            }

            Section("Members (\(organization.members.count))") {
                ForEach(organization.members) { member in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(member.name).font(.subheadline.bold())
                            Text(member.email).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(member.role.rawValue.capitalized)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(roleColor(member.role).opacity(0.1))
                            .foregroundStyle(roleColor(member.role))
                            .clipShape(Capsule())
                    }
                }
            }

            Section("Teams (\(organization.teams.count))") {
                if organization.teams.isEmpty {
                    Text("No teams defined.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(organization.teams) { team in
                        HStack {
                            Text(team.name)
                            Spacer()
                            Text("\(team.memberIDs.count) members").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(organization.name)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func roleColor(_ role: TeamRole) -> Color {
        switch role {
        case .owner: return .purple
        case .admin: return .red
        case .developer: return .blue
        case .viewer: return .secondary
        }
    }
}
