import SwiftUI

struct DeveloperTeamManagerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAddMember = false
    @State private var newMemberName = ""
    @State private var newMemberEmail = ""
    @State private var selectedRole: TeamRole = .developer

    var body: some View {
        List {
            Section {
                if store.teamMembers.isEmpty {
                    Text("No team members yet. Invite collaborators to your project.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.teamMembers) { member in
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
                    .onDelete(perform: deleteMember)
                }
            } header: {
                Text("Team Members")
            }
        }
        .navigationTitle("Team Management")
        .toolbar {
            Button { showingAddMember = true } label: { Image(systemName: "person.badge.plus") }
        }
        .sheet(isPresented: $showingAddMember) {
            NavigationStack {
                Form {
                    Section("Member Details") {
                        TextField("Name", text: $newMemberName)
                        TextField("Email", text: $newMemberEmail)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }

                    Section("Role") {
                        Picker("Role", selection: $selectedRole) {
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
                        Button("Invite") { addMember() }
                            .disabled(newMemberName.isEmpty || newMemberEmail.isEmpty)
                    }
                }
            }
        }
    }

    private func addMember() {
        let member = TeamMember(name: newMemberName, email: newMemberEmail, role: selectedRole)
        var current = store.teamMembers
        current.append(member)
        store.saveTeamMembers(current)
        showingAddMember = false
        newMemberName = ""
        newMemberEmail = ""
    }

    private func deleteMember(at offsets: IndexSet) {
        var current = store.teamMembers
        current.remove(atOffsets: offsets)
        store.saveTeamMembers(current)
    }
}
