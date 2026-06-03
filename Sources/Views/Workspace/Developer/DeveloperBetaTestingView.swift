import SwiftUI

struct DeveloperBetaTestingView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddTester = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            appSelector

            Picker("Beta Management", selection: $selectedTab) {
                Text("Groups").tag(0)
                Text("Testers").tag(1)
                Text("Feedback").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            if let appID = selectedAppID {
                switch selectedTab {
                case 0: groupsView(appID: appID)
                case 1: testersView(appID: appID)
                case 2: feedbackView(appID: appID)
                default: EmptyView()
                }
            } else {
                EmptyStateView(icon: "person.3.sequence.fill", title: "Select an App", message: "Choose an application to manage its beta testing program.")
                    .frame(maxHeight: .infinity)
            }
        }
        .navigationTitle("Beta Testing")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
        .sheet(isPresented: $showingAddTester) {
            AddTesterSheet(appID: selectedAppID ?? UUID())
        }
    }

    private var appSelector: some View {
        Picker("Project", selection: $selectedAppID) {
            ForEach(appService.apps) { app in
                Text(app.name).tag(Optional(app.id))
            }
        }
        .pickerStyle(.menu)
        .padding()
    }

    private func groupsView(appID: UUID) -> some View {
        List {
            Section("Testing Groups") {
                let groups = DeveloperPersistentStore.shared.betaGroups.filter { $0.appID == appID }
                if groups.isEmpty {
                    Text("No testing groups defined.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(group.name).font(.subheadline.bold())
                                Spacer()
                                Text("\(group.testerEmails.count) Testers").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    var current = DeveloperPersistentStore.shared.betaGroups
                    current.append(BetaGroup(appID: appID, name: "New Group"))
                    DeveloperPersistentStore.shared.saveBetaGroups(current)
                } label: {
                    Label("Create Testing Group", systemImage: "person.3.badge.plus")
                }
            }
        }
    }

    private func testersView(appID: UUID) -> some View {
        List {
            Section("Active Testers") {
                let testers = DeveloperPersistentStore.shared.betaTesters.filter { $0.appID == appID }
                if testers.isEmpty {
                    Text("No beta testers invited.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(testers) { tester in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tester.email).font(.subheadline.bold())
                                Text("Active since \(tester.joinedAt.formatted(date: .abbreviated, time: .omitted))").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Circle().fill(.green).frame(width: 8, height: 8)
                        }
                    }
                }
            }

            Section {
                Button { showingAddTester = true } label: {
                    Label("Invite Beta Tester", systemImage: "person.badge.plus")
                }
            }
        }
    }

    private func feedbackView(appID: UUID) -> some View {
        List {
            Section("Incoming Reports") {
                let feedbacks = DeveloperPersistentStore.shared.betaFeedback.filter { $0.appID == appID }
                if feedbacks.isEmpty {
                    Text("No feedback reports received yet.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(feedbacks) { report in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(report.version).font(.caption.bold()).foregroundStyle(.secondary)
                                Spacer()
                                Text(report.type).font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(report.type == "CRASH" ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                    .foregroundStyle(report.type == "CRASH" ? .red : .blue)
                                    .clipShape(Capsule())
                            }
                            Text(report.content).font(.subheadline)
                            Text("Reported by tester • \(report.timestamp.formatted(date: .abbreviated, time: .shortened))").font(.system(size: 8)).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct AddTesterSheet: View {
    let appID: UUID
    @Environment(\.dismiss) var dismiss
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Tester Details") {
                    TextField("Email Address", text: $email).keyboardType(.emailAddress).autocapitalization(.none)
                    Text("Invitations grant access to the most recent 'Public Beta' build.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Invite Tester")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        var current = DeveloperPersistentStore.shared.betaTesters
                        current.append(BetaTester(appID: appID, email: email))
                        DeveloperPersistentStore.shared.saveBetaTesters(current)
                        dismiss()
                    }.disabled(!email.contains("@") || !email.contains("."))
                }
            }
        }
    }
}
