import SwiftUI

struct NetworkStatusView: View {
    let quality: MeetingNetworkQuality
    let latencyMs: Int
    let packetLossPercent: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Network", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                qualityBars
            }
            Text("\(quality.label) · \(latencyMs)ms · \(String(format: "%.1f", packetLossPercent))% loss")
                .font(.caption)
                .foregroundStyle(.secondary)
            if quality == .poor {
                Text("Poor connection detected. Consider disabling camera.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var qualityBars: some View {
        HStack(spacing: 3) {
            ForEach(1...4, id: \.self) { level in
                Capsule()
                    .fill(level <= quality.rawValue ? Color.green : Color.secondary.opacity(0.25))
                    .frame(width: 5, height: CGFloat(level * 4))
            }
        }
    }
}
