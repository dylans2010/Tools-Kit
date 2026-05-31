import SwiftUI

struct DataHandlingPolicyBuilderView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddPolicy = false

    @State private var policies: [DataPolicy] = [
        DataPolicy(name: "User Account Data", retention: "7 years", logic: "Full encryption at rest"),
        DataPolicy(name: "Application Logs", retention: "90 days", logic: "Redacted PII")
    ]

    var body: some View {
        List {
            Section("Privacy Compliance") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass").foregroundStyle(.blue)
                        Text("Data Retention Policies").font(.subheadline.bold())
                    }
                    Text("Declare how long user and application data is stored. These policies are reflected in your public Privacy Manifest.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                Picker("Active App", selection: $selectedAppID) {
                    Text("Select App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            if selectedAppID != nil {
                Section("Established Policies") {
                    if policies.isEmpty {
                        EmptyStateView(icon: "lock.shield", title: "No Policies", message: "Define your data handling procedures to satisfy regulatory requirements.")
                    } else {
                        ForEach(policies) { policy in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(policy.name).font(.subheadline.bold())
                                    Spacer()
                                    Text(policy.retention).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                                }
                                Text(policy.logic).font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section {
                    Button { showingAddPolicy = true } label: {
                        Label("Add Policy Definition", systemImage: "plus.circle.fill").font(.subheadline.bold())
                    }
                }
            }
        }
        .navigationTitle("Data Policies")
        .sheet(isPresented: $showingAddPolicy) { addPolicySheet }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private var addPolicySheet: some View {
        NavigationStack {
            Form {
                Section("Policy Context") {
                    TextField("Data Category", text: .constant(""), prompt: Text("Data Category"))
                    TextField("Retention Period", text: .constant(""), prompt: Text("Retention Period"))
                }
                Section("Handling Logic") {
                    TextEditor(text: .constant("")).frame(height: 100)
                }
            }
            .navigationTitle("New Policy")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddPolicy = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { showingAddPolicy = false } }
            }
        }
    }
}

struct DataPolicy: Identifiable {
    let id = UUID()
    let name: String
    let retention: String
    let logic: String
}
