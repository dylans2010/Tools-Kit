import SwiftUI

struct Diag_BatteryDrainSimView: View {
    @State private var simulatedLevel: Double = 100
    @State private var isSimulating = false
    @State private var drainRate: Double = 5
    @State private var timer: Timer?
    @State private var timeElapsed: Int = 0

    var body: some View {
        Form {
            Section("Battery Drain Simulation") {
                VStack(spacing: 16) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(height: 50)

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(drainColor)
                                .frame(width: geo.size.width * CGFloat(simulatedLevel / 100), height: 50)
                                .animation(.linear(duration: 0.5), value: simulatedLevel)
                        }
                        .frame(height: 50)
                    }

                    Text("\(Int(simulatedLevel))%")
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundStyle(drainColor)

                    if isSimulating {
                        Text("Time: \(timeElapsed)s")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Section("Drain Rate") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Drain speed: \(drainRate, specifier: "%.0f")%/sec")
                        .font(.subheadline)
                    Slider(value: $drainRate, in: 1...20, step: 1)
                }
            }

            Section {
                Button {
                    if isSimulating { stopSimulation() } else { startSimulation() }
                } label: {
                    HStack {
                        Image(systemName: isSimulating ? "stop.circle.fill" : "play.circle.fill")
                        Text(isSimulating ? "Stop Simulation" : "Start Drain Simulation")
                    }
                }

                Button("Reset to 100%") {
                    stopSimulation()
                    simulatedLevel = 100
                    timeElapsed = 0
                }
            }

            Section {
                Text("This is a visual-only simulation. It does not affect your actual battery level.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Battery Drain Sim")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopSimulation() }
    }

    private var drainColor: Color {
        if simulatedLevel > 50 { return .green }
        if simulatedLevel > 20 { return .yellow }
        return .red
    }

    private func startSimulation() {
        isSimulating = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeElapsed += 1
            simulatedLevel = max(0, simulatedLevel - drainRate)
            if simulatedLevel <= 0 {
                stopSimulation()
            }
        }
    }

    private func stopSimulation() {
        timer?.invalidate()
        timer = nil
        isSimulating = false
    }
}
