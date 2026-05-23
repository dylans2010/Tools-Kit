import SwiftUI

struct Diag_PowerMetricsView: View {
    var body: some View {
        List {
            Section("Instantaneous Draw") {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("420 mW")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("Total Power")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.yellow)
                    }
                    .padding()
                }
            }

            Section("Subsystem Power") {
                PowerRow(label: "Display", value: "180 mW", percent: 0.42)
                PowerRow(label: "CPU/SoC", value: "120 mW", percent: 0.28)
                PowerRow(label: "Radios (WiFi/Cell)", value: "80 mW", percent: 0.19)
                PowerRow(label: "Other", value: "40 mW", percent: 0.11)
            }

            Section("Efficiency") {
                LabeledContent("Energy Impact", value: "Low")
                LabeledContent("Background Task Cost", value: "2% / hr")
            }
        }
        .navigationTitle("Power Metrics")
    }
}

struct PowerRow: View {
    let label: String
    let value: String
    let percent: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(value)
                    .monospacedDigit()
            }
            ProgressView(value: percent)
                .tint(.yellow)
        }
        .padding(.vertical, 4)
    }
}
