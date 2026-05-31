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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Internal QA").font(.subheadline.bold())
                        Spacer()
                        Text("12 Testers").font(.caption).foregroundStyle(.secondary)
                    }
                    Text("Auto-provisioned for every build.").font(.caption2).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Public Beta").font(.subheadline.bold())
                        Spacer()
                        Text("248 Testers").font(.caption).foregroundStyle(.secondary)
                    }
                    Text("Manual enrollment via public link.").font(.caption2).foregroundStyle(.secondary)
                }
            }

            Section {
                Button { /* group creation logic */ } label: {
                    Label("Create Testing Group", systemImage: "person.3.badge.plus")
                }
            }
        }
    }

    private func testersView(appID: UUID) -> some View {
        List {
            Section("Active Testers") {
                // In a production app, this would fetch from a BetaTesterService
                ForEach(0..<5) { i in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("tester\(i)@example.com").font(.subheadline.bold())
                            Text("Active since \(Date().addingTimeInterval(-Double(i)*86400).formatted(date: .abbreviated, time: .omitted))").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Circle().fill(.green).frame(width: 8, height: 8)
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
                ForEach(0..<3) { i in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("v1.2.0 (4\(i))").font(.caption.bold()).foregroundStyle(.secondary)
                            Spacer()
                            Text(i == 0 ? "CRASH" : "FEEDBACK").font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(i == 0 ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                .foregroundStyle(i == 0 ? .red : .blue)
                                .clipShape(Capsule())
                        }
                        Text(i == 0 ? "Unexpected signal SIGABRT on startup." : "The new UI layout is much cleaner, but the font size on labels is a bit small.")
                            .font(.subheadline)
                        Text("Reported by tester • \(i+1)h ago").font(.system(size: 8)).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
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
                        // send invitation logic
                        dismiss()
                    }.disabled(!email.contains("@") || !email.contains("."))
                }
            }
        }
    }
}
