import SwiftUI

struct DeveloperBetaTestingView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var selectedAppID: UUID?
    @State private var showingCreateGroup = false
    @State private var groupName = ""
    @State private var showingAddTester = false
    @State private var testerEmail = ""
    @State private var selectedGroupID: UUID?

    var betaGroups: [BetaGroup] {
        store.betaGroups.filter { $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("Project", selection: $selectedAppID) {
                    Text("Select a Project").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Beta Testing Groups") {
                if let appID = selectedAppID {
                    if betaGroups.isEmpty {
                        VStack(spacing: 12) {
                            EmptyStateView(icon: "person.3.sequence.fill", title: "No Beta Groups", message: "No active beta groups found for this project.")

                            Button {
                                showingCreateGroup = true
                            } label: {
                                Label("Create Beta Group", systemImage: "plus.circle.fill")
                                    .font(.subheadline.bold())
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 20)
                    } else {
                        ForEach(betaGroups) { group in
                            VStack(alignment: .leading) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(group.name).font(.subheadline.bold())
                                        Text("\(group.testerEmails.count) testers").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        selectedGroupID = group.id
                                        showingAddTester = true
                                    } label: {
                                        Image(systemName: "person.badge.plus")
                                    }
                                }

                                if !group.testerEmails.isEmpty {
                                    DisclosureGroup("Testers") {
                                        ForEach(group.testerEmails, id: \.self) { email in
                                            Text(email).font(.caption)
                                        }
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                        .onDelete(perform: deleteGroups)

                        Button {
                            showingCreateGroup = true
                        } label: {
                            Label("Add Group", systemImage: "plus")
                        }
                    }
                } else {
                    Text("Select a project above to manage beta testing invitations and groups.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Beta Testing")
        .sheet(isPresented: $showingCreateGroup) {
            createGroupSheet
        }
        .sheet(isPresented: $showingAddTester) {
            addTesterSheet
        }
    }

    private var addTesterSheet: some View {
        NavigationStack {
            Form {
                TextField("Tester Email", text: $testerEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .navigationTitle("Invite Tester")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddTester = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") { addTester() }
                        .disabled(!testerEmail.contains("@"))
                }
            }
        }
    }

    private func addTester() {
        guard let groupID = selectedGroupID else { return }
        var current = store.betaGroups
        if let index = current.firstIndex(where: { $0.id == groupID }) {
            current[index].testerEmails.append(testerEmail)
            store.saveBetaGroups(current)
            testerEmail = ""
            showingAddTester = false
        }
    }

    private var createGroupSheet: some View {
        NavigationStack {
            Form {
                Section("Group Details") {
                    TextField("Group Name", text: $groupName)
                }
            }
            .navigationTitle("New Beta Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingCreateGroup = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if let appID = selectedAppID {
                            let newGroup = BetaGroup(appID: appID, name: groupName)
                            var current = store.betaGroups
                            current.append(newGroup)
                            store.saveBetaGroups(current)
                            groupName = ""
                            showingCreateGroup = false
                        }
                    }
                    .disabled(groupName.isEmpty)
                }
            }
        }
    }

    private func deleteGroups(at offsets: IndexSet) {
        var current = store.betaGroups
        let toDelete = offsets.map { betaGroups[$0].id }
        current.removeAll { toDelete.contains($0.id) }
        store.saveBetaGroups(current)
    }
}
