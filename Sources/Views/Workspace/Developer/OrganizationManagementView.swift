import SwiftUI

struct OrganizationManagementView: View {
    @ObservedObject var orgService = OrganizationService.shared
    @State private var showingCreate = false
    @State private var newOrgName = ""

    var body: some View {
        List {
            Section("Your Organizations") {
                if orgService.organizations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "building.2")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("You are not part of any organizations. Create one to manage teams and shared projects.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(orgService.organizations) { org in
                        NavigationLink(destination: Text(org.name).navigationTitle(org.name)) {
                            VStack(alignment: .leading) {
                                Text(org.name).font(.headline)
                                Text("\(org.members.count) members • \(org.teams.count) teams").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Organizations")
        .toolbar {
            Button { showingCreate = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showingCreate) {
            createOrgSheet
        }
    }

    private var createOrgSheet: some View {
        NavigationStack {
            Form {
                TextField("Organization Name", text: $newOrgName)
            }
            .navigationTitle("Create Organization")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCreate = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createOrg()
                    }
                    .disabled(newOrgName.isEmpty)
                }
            }
        }
    }

    private func createOrg() {
        Task {
            try? await orgService.createOrganization(name: newOrgName)
            await MainActor.run {
                showingCreate = false
                newOrgName = ""
            }
        }
    }
}
