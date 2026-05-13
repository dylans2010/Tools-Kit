
import SwiftUI

struct SDKSandboxEnvironmentView: View {
    @State private var isolationLevel: Isolation = .medium
    @State private var mockDataEnabled = true

    enum Isolation: String, CaseIterable {
        case low, medium, high
    }

    var body: some View {
        Form {
            Section("Sandbox Configuration") {
                Picker("Isolation Level", selection: $isolationLevel) {
                    ForEach(Isolation.allCases, id: \.self) { i in
                        Text(i.rawValue.capitalized).tag(i)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Use Mock Data in Sandbox", isOn: $mockDataEnabled)
            }

            Section("Network Mirroring") {
                Button("Mirror Production Traffic", systemImage: "arrow.triangle.2.circlepath") { }
                Text("Simulate real-world traffic patterns using anonymized production data.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sandbox Environment")
    }
}
