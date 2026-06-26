import SwiftUI

struct OpenClawConnectionStatusView: View {
    let state: ConnectionState

    private var color: Color {
        switch state {
        case .idle: return .secondary
        case .connecting, .socketConnected, .waitingChallenge, .authenticating, .reconnecting: return .orange
        case .connected: return .green
        case .failed: return .red
        }
    }

    private var statusText: String {
        switch state {
        case .idle: return "Disconnected"
        case .connecting: return "Connecting"
        case .socketConnected: return "Socket Connected"
        case .waitingChallenge: return "Waiting Challenge"
        case .authenticating: return "Authenticating"
        case .connected: return "Connected"
        case .failed(let reason): return "Failed: \(String(describing: reason))"
        case .reconnecting(let attempt): return "Reconnecting (Attempt \(attempt + 1))"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
