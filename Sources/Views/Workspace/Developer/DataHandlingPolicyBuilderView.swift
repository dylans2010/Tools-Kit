import SwiftUI

struct DataHandlingPolicyBuilderView: View {
    let appID: UUID
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var policy: DataHandlingPolicy

    init(appID: UUID) {
        self.appID = appID
        let existing = DeveloperPersistentStore.shared.dataHandlingPolicies.first(where: { $0.appID == appID })
        _policy = State(initialValue: existing ?? DataHandlingPolicy(appID: appID))
    }

    var body: some View {
        Form {
            Section("Data Retention") {
                TextField("Retention Period (e.g. 90 days)", text: $policy.retentionPeriod)
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
                    var current = store.dataHandlingPolicies
                    if let index = current.firstIndex(where: { $0.appID == appID }) {
                        current[index] = policy
                        current[index].updatedAt = Date()
                    } else {
                        current.append(policy)
                    }
                    store.saveDataHandlingPolicies(current)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Data Handling Policy")
    }
}
