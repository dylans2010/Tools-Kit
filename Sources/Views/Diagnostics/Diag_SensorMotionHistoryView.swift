import SwiftUI
import CoreMotion

struct Diag_SensorMotionHistoryView: View {
    @State private var activities: [String] = []
    @State private var count = 0
    private let manager = CMMotionActivityManager()

    var body: some View {
        Form {
            Section("Today") {
                LabeledContent("Activity Records") { Text("\(count)").monospacedDigit() }
                if activities.isEmpty {
                    Text("No activity records yet today, or Motion & Fitness is not authorised.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activities, id: \.self) { a in Text(a).font(.caption) }
                }
            }
            Section { Button("Refresh") { load() } }
        }
        .navigationTitle("Motion History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        let start = Calendar.current.startOfDay(for: Date())
        manager.queryActivityStarting(from: start, to: Date(), to: .main) { list, _ in
            guard let list = list else { return }
            count = list.count
            activities = list.map { a in
                var parts: [String] = []
                if a.stationary { parts.append("Stationary") }
                if a.walking { parts.append("Walking") }
                if a.running { parts.append("Running") }
                if a.cycling { parts.append("Cycling") }
                if a.automotive { parts.append("Driving") }
                if a.unknown { parts.append("Unknown") }
                return "\(a.startDate, style: .time): \(parts.joined(separator: ", "))"
            }
        }
    }
}
