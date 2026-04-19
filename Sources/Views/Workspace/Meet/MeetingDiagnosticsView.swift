import SwiftUI

struct MeetingDiagnosticsView: View {
    let diagnostics: MeetingDiagnosticsState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Diagnostics")
                .font(.headline)
            LabeledContent("Connection", value: diagnostics.connectionState)
            LabeledContent("Network", value: diagnostics.networkQuality)
            LabeledContent("Latency", value: "\(diagnostics.latencyMs) ms")
            LabeledContent("Packet Loss", value: String(format: "%.1f%%", diagnostics.packetLossPercent))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
