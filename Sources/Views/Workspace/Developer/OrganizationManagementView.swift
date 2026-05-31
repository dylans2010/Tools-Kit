import SwiftUI

struct OrganizationManagementView: View {
    @ObservedObject var orgService = OrganizationService.shared
    @State private var showingAddMember = false
    @State private var email = ""
    @State private var role: TeamRole = .developer

    var body: some View {
        List {
            Section("Organization Profile") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05))
                            Image(systemName: "building.2.fill").font(.title2).foregroundStyle(.secondary)
                        }
                        .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(orgService.organizationName).font(.headline)
                            Text("Enterprise Verified").font(.caption).foregroundStyle(.green)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Team Members") {
                if orgService.members.isEmpty {
                    Text("No other members in this organization.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(orgService.members) { member in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name).font(.subheadline.bold())
                                Text(member.email).font(.system(size: 9)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(member.role.rawValue.uppercased())
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(member.role.color.opacity(0.1))
                                .foregroundStyle(member.role.color)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Section {
                Button { showingAddMember = true } label: {
                    Label("Invite Team Member", systemImage: "person.badge.plus.fill").font(.subheadline.bold())
                }
            }

            Section("Legal & Compliance") {
                NavigationLink(destination: Text("Service Agreement")) { Label("Developer Agreement", systemImage: "doc.text.fill") }
                NavigationLink(destination: Text("Tax Documents")) { Label("Tax Information", systemImage: "banknote.fill") }
                NavigationLink(destination: Text("Banking")) { Label("Payout Methods", systemImage: "creditcard.fill") }
            }
        }
        .navigationTitle("Organization")
        .sheet(isPresented: $showingAddMember) {
            NavigationStack {
                Form {
                    Section("Member Details") {
                        TextField("Email Address", text: $email).keyboardType(.emailAddress).autocapitalization(.none)
                        Picker("Role", selection: $role) {
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
                                try? await orgService.inviteMember(email: email, role: role)
                                await MainActor.run { showingAddMember = false; email = "" }
                            }
                        }
                        .disabled(email.isEmpty)
                    }
                }
            }
        }
    }
}
