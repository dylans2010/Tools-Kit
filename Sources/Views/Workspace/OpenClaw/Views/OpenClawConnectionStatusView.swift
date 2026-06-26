import SwiftUI

struct OpenClawConnectionStatusView: View {
    let state: ConnectionState

    private var color: Color {
        switch state {
        case .idle, .disconnected:
            return .secondary
        case .discovering, .gatewaySelected, .resolvingAuthentication, .pairing, .connecting, .socketConnected, .waitingForChallenge, .authenticating, .authenticated, .disconnecting:
            return .orange
        case .ready:
            return .green
        case .failed:
            return .red
        }
    }

    private var statusText: String {
        switch state {
        case .idle: return "Idle"
        case .discovering: return "Discovering"
        case .gatewaySelected: return "Gateway Selected"
        case .resolvingAuthentication: return "Resolving Auth"
        case .pairing: return "Pairing"
        case .connecting: return "Connecting"
        case .socketConnected: return "Socket Connected"
        case .waitingForChallenge: return "Waiting Challenge"
        case .authenticating: return "Authenticating"
        case .authenticated: return "Authenticated"
        case .ready: return "Connected"
        case .disconnecting: return "Disconnecting"
        case .disconnected: return "Disconnected"
        case .failed(let reason): return "Failed: \(String(describing: reason))"
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
