import SwiftUI

struct DataHandlingPolicyBuilderView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var policy: DataHandlingPolicy
    @State private var showingSavedAlert = false

    init(appID: UUID) {
        self.appID = appID
        _policy = State(initialValue: DataHandlingPolicy(appID: appID))
    }

    var body: some View {
        Form {
            Section("Data Retention") {
                VStack(alignment: .leading) {
                    Text("Retention Period (Days)").font(.caption).foregroundStyle(.secondary)
                    TextField("90", text: $policy.retentionPeriod)
                        .keyboardType(.numberPad)
                }
                VStack(alignment: .leading) {
                    Text("Deletion Policy").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $policy.deletionPolicyDescription)
                        .frame(height: 100)
                }
            }

            Section("Third-Party Sharing") {
                Toggle("Share data with third parties", isOn: $policy.sharesWithThirdParties)
                if policy.sharesWithThirdParties {
                    Text("Declare all third-party partners below.").font(.caption).foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Save Policy") {
                    savePolicy()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Data Handling Policy")
        .alert("Policy Saved", isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The data handling policy for your application has been successfully persisted.")
        }
    }

    private func savePolicy() {
        policy.updatedAt = Date()
        // In this local persistence model, we would save to a dedicated policies collection in DeveloperPersistentStore
        // For now, we simulate the completion of the persistence workflow.
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                showingSavedAlert = true
            }
        }
    }
}
