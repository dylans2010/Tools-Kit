import SwiftUI

struct LMLinkConnectionStatusView: View {
    @StateObject private var connectionManager = LMConnectionManager.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(connectionManager.selectedDevice?.name ?? "No Device Selected")
                    .font(.headline)

                if let device = connectionManager.selectedDevice {
                    HStack {
                        Circle()
                            .fill(device.status == .online ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(device.status == .online ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if connectionManager.isConnecting {
                ProgressView()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
