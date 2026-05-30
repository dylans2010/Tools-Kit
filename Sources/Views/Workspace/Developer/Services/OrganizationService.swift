import Foundation

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
            let updatedOrganizations = currentOrgs
            await MainActor.run {
                self.organizations = updatedOrganizations
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

    public func deleteOrganization(id: UUID) async throws {
        var currentOrgs = store.organizations
        currentOrgs.removeAll { $0.id == id }
        store.saveOrganizations(currentOrgs)
        let updatedOrganizations = currentOrgs
        await MainActor.run {
            self.organizations = updatedOrganizations
        }
    }
}
