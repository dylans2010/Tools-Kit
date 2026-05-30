import Foundation

/**
 SYSTEM DOMAIN: Configuration, Lifecycle
 RESPONSIBILITY: Manages developer organizations, teams, and member roles.
 */
public class OrganizationService: ObservableObject {
    public static let shared = OrganizationService()
    private let store = DeveloperPersistentStore.shared

    @Published public var organizations: [DeveloperOrganization] = []

    private init() {
        loadOrganizations()
    }

    public func loadOrganizations() {
        self.organizations = store.organizations
    }

    public func createOrganization(name: String) async throws {
        var currentOrgs = store.organizations
        let org = DeveloperOrganization(name: name)
        currentOrgs.append(org)
        store.saveOrganizations(currentOrgs)

        let updatedOrganizations = currentOrgs
        await MainActor.run {
            self.organizations = updatedOrganizations
        }
    }

    public func updateOrganization(_ org: DeveloperOrganization) async throws {
        var currentOrgs = store.organizations
        if let index = currentOrgs.firstIndex(where: { $0.id == org.id }) {
            currentOrgs[index] = org
            store.saveOrganizations(currentOrgs)
            let updatedOrganizations = currentOrgs
            await MainActor.run {
                self.organizations = updatedOrganizations
            }
        }
    }

    public func addMember(orgID: UUID, email: String, role: OrgRole) async throws {
        var currentOrgs = store.organizations
        if let index = currentOrgs.firstIndex(where: { $0.id == orgID }) {
            let member = OrgMember(accountID: UUID(), name: email.components(separatedBy: "@").first ?? "User", email: email, role: role)
            currentOrgs[index].members.append(member)
            store.saveOrganizations(currentOrgs)

            // Sync with teamMembers collection
            var currentMembers = store.teamMembers
            currentMembers.append(member)
            store.saveTeamMembers(currentMembers)

            let updatedOrganizations = currentOrgs
            await MainActor.run {
                self.organizations = updatedOrganizations
            }
        }
    }

    public func removeMember(orgID: UUID, memberID: UUID) async throws {
        var currentOrgs = store.organizations
        if let index = currentOrgs.firstIndex(where: { $0.id == orgID }) {
            currentOrgs[index].members.removeAll { $0.id == memberID }
            store.saveOrganizations(currentOrgs)

            // Sync with teamMembers collection
            var currentMembers = store.teamMembers
            currentMembers.removeAll { $0.id == memberID }
            store.saveTeamMembers(currentMembers)

            let updatedOrganizations = currentOrgs
            await MainActor.run {
                self.organizations = updatedOrganizations
            }
        }
    }

    public func updateMemberRole(orgID: UUID, memberID: UUID, newRole: OrgRole) async throws {
        var currentOrgs = store.organizations
        if let index = currentOrgs.firstIndex(where: { $0.id == orgID }) {
            if let memberIndex = currentOrgs[index].members.firstIndex(where: { $0.id == memberID }) {
                currentOrgs[index].members[memberIndex].role = newRole
                store.saveOrganizations(currentOrgs)

                // Sync with teamMembers collection
                var currentMembers = store.teamMembers
                if let idx = currentMembers.firstIndex(where: { $0.id == memberID }) {
                    currentMembers[idx].role = newRole
                    store.saveTeamMembers(currentMembers)
                }

                let updatedOrganizations = currentOrgs
                await MainActor.run {
                    self.organizations = updatedOrganizations
                }
            }
        }
    }

    public func createTeam(orgID: UUID, name: String) async throws {
        var currentOrgs = store.organizations
        if let index = currentOrgs.firstIndex(where: { $0.id == orgID }) {
            let team = DeveloperTeam(name: name, organizationID: orgID)
            currentOrgs[index].teams.append(team)
            store.saveOrganizations(currentOrgs)
            let updatedOrganizations = currentOrgs
            await MainActor.run {
                self.organizations = updatedOrganizations
            }
        }
    }
}
