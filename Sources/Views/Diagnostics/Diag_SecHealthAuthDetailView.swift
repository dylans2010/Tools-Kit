import SwiftUI
import HealthKit


struct Diag_SecHealthAuthDetailView: View {
    @State private var rows: [(String, String)] = []

    var body: some View {
        Form {
            Section("Results") {
                ForEach(rows, id: \.0) { row in
                    LabeledContent(row.0) { Text(row.1).font(.caption) }
                }
            }

            Section {
                Button { load() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") }
                }
            }
        }
        .navigationTitle("Health Auth Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Health Available", HKHealthStore.isHealthDataAvailable() ? "Yes" : "No"),
            ("Step Count Authorization", String(describing: HKHealthStore().authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .stepCount)!)))
        ]
    }
}
