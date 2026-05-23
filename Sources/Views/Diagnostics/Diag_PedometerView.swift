import SwiftUI
import CoreMotion

struct Diag_PedometerView: View {
    @State private var steps: Int = 0
    @State private var distance: Double = 0
    @State private var floorsAscended: Int = 0
    @State private var floorsDescended: Int = 0
    @State private var isAvailable = false
    @State private var isMonitoring = false
    private let pedometer = CMPedometer()

    var body: some View {
        Form {
            Section("Step Counter") {
                VStack(spacing: 12) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 44))
                        .foregroundStyle(.green)
                    Text("\(steps)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("Steps Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Details") {
                LabeledContent("Distance") {
                    Text(String(format: "%.1f m", distance)).monospacedDigit()
                }
                LabeledContent("Floors Ascended") {
                    Text("\(floorsAscended)").monospacedDigit()
                }
                LabeledContent("Floors Descended") {
                    Text("\(floorsDescended)").monospacedDigit()
                }
            }

            Section("Capabilities") {
                LabeledContent("Step Counting") {
                    Text(CMPedometer.isStepCountingAvailable() ? "Available" : "Unavailable")
                        .foregroundStyle(CMPedometer.isStepCountingAvailable() ? .green : .red)
                }
                LabeledContent("Distance Estimation") {
                    Text(CMPedometer.isDistanceAvailable() ? "Available" : "Unavailable")
                        .foregroundStyle(CMPedometer.isDistanceAvailable() ? .green : .red)
                }
                LabeledContent("Floor Counting") {
                    Text(CMPedometer.isFloorCountingAvailable() ? "Available" : "Unavailable")
                        .foregroundStyle(CMPedometer.isFloorCountingAvailable() ? .green : .red)
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "figure.walk")
                        Text(isMonitoring ? "Stop" : "Start Tracking")
                    }
                }
            }
        }
        .navigationTitle("Pedometer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isAvailable = CMPedometer.isStepCountingAvailable()
            loadTodayData()
        }
        .onDisappear { stopMonitoring() }
    }

    private func loadTodayData() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        pedometer.queryPedometerData(from: startOfDay, to: Date()) { data, _ in
            DispatchQueue.main.async {
                guard let data = data else { return }
                steps = data.numberOfSteps.intValue
                distance = data.distance?.doubleValue ?? 0
                floorsAscended = data.floorsAscended?.intValue ?? 0
                floorsDescended = data.floorsDescended?.intValue ?? 0
            }
        }
    }

    private func startMonitoring() {
        isMonitoring = true
        pedometer.startUpdates(from: Date()) { data, _ in
            DispatchQueue.main.async {
                guard let data = data else { return }
                steps = data.numberOfSteps.intValue
                distance = data.distance?.doubleValue ?? 0
            }
        }
    }

    private func stopMonitoring() {
        pedometer.stopUpdates()
        isMonitoring = false
    }
}
