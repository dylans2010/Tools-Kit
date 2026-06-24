import SwiftUI

struct OpenClawConnectionStatusView: View {
    let isConnected: Bool
    let deviceName: String?

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? .green : .red)
                .frame(width: 8, height: 8)

            if isConnected, let name = deviceName {
                Text("Connected to \(name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
}
