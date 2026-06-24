import SwiftUI

struct OpenClawConnectionStatusView: View {
    let state: ConnectionState

    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch state {
        case .idle: return .gray
        case .connecting, .authenticating: return .orange
        case .connected: return .green
        case .failed: return .red
        }
    }

    private var statusText: String {
        switch state {
        case .idle: return "Disconnected"
        case .connecting: return "Connecting"
        case .authenticating: return "Authenticating"
        case .connected: return "Connected"
        case .failed: return "Error"
        }
    }
}
