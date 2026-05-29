import SwiftUI

struct DataHandlingPolicyBuilderView: View {
    @State private var policy = DataHandlingPolicy(appID: UUID())

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
                    // Save logic
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Data Handling Policy")
    }
}
