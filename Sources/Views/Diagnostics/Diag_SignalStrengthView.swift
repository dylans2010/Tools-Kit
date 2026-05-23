import SwiftUI

struct Diag_SignalStrengthView: View {
    @State private var rsrp: Int = -95
    @State private var rsrq: Int = -12
    @State private var sinr: Int = 15

    var body: some View {
        List {
            Section("Radio Signal Metrics") {
                MetricRow(label: "RSRP (Reference Signal Received Power)", value: "\(rsrp) dBm", description: "Range: -140 (poor) to -44 (excellent)", progress: Double(rsrp + 140) / 96.0)

                MetricRow(label: "RSRQ (Reference Signal Received Quality)", value: "\(rsrq) dB", description: "Range: -20 (poor) to -3 (excellent)", progress: Double(rsrq + 20) / 17.0)

                MetricRow(label: "SINR (Signal to Interference & Noise Ratio)", value: "\(sinr) dB", description: "Range: -10 (poor) to 30 (excellent)", progress: Double(sinr + 10) / 40.0)
            }

            Section("Status") {
                LabeledContent("Signal Strength", value: signalLabel)
                    .foregroundStyle(signalColor)
            }

            Section(footer: Text("Values are approximate. Precise cellular metrics require Field Test Mode (*3001#12345#*).")) {
                EmptyView()
            }
        }
        .navigationTitle("Signal Strength")
    }

    private var signalLabel: String {
        if rsrp > -80 { return "Excellent" }
        if rsrp > -90 { return "Good" }
        if rsrp > -100 { return "Fair" }
        return "Poor"
    }

    private var signalColor: Color {
        if rsrp > -90 { return .green }
        if rsrp > -100 { return .orange }
        return .red
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let description: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(value)
                    .font(.headline.monospacedDigit())
            }

            ProgressView(value: max(0, min(1, progress)))

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
