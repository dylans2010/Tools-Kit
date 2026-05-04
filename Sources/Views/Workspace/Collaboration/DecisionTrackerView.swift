import SwiftUI

struct DecisionTrackerView: View {
    @StateObject private var service = DecisionTrackingService.shared

    var body: some View {
        List(service.decisions) { decision in
            VStack(alignment: .leading) {
                Text(decision.title).font(.headline)
                Text(decision.outcome).font(.subheadline)
                Text(decision.date, style: .date).font(.caption).foregroundColor(.secondary)
            }
        }
        .navigationTitle("Decisions")
        .toolbar {
            Button("New Decision") {
                service.recordDecision(title: "Sample Decision", outcome: "Approved")
            }
        }
    }
}
