import SwiftUI

struct TeamManagementView: View {
    let orgID: UUID
    @ObservedObject var orgService = OrganizationService.shared
    @State private var showingCreate = false
    @State private var newTeamName = ""

    var org: DeveloperOrganization? {
        orgService.organizations.first { $0.id == orgID }
    }

    var body: some View {
        List {
            if let org = org {
                Section("Teams") {
                    if org.teams.isEmpty {
                        Text("No teams created in this organization.").foregroundStyle(.secondary)
                    } else {
                        ForEach(org.teams) { team in
                            VStack(alignment: .leading) {
                                Text(team.name).font(.headline)
                                Text("\(team.members.count) members").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Team Management")
        .toolbar {
            Button { showingCreate = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showingCreate) {
            createTeamSheet
        }
    }

    private var createTeamSheet: some View {
        NavigationStack {
            Form {
                TextField("Team Name", text: $newTeamName)
            }
            .navigationTitle("Create Team")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCreate = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTeam()
                    }
                    .disabled(newTeamName.isEmpty)
                }
            }
        }
    }

    private func createTeam() {
        Task {
            try? await orgService.createTeam(orgID: orgID, name: newTeamName)
            await MainActor.run {
                showingCreate = false
                newTeamName = ""
            }
        }
    }
}
