import Foundation
import Observation

public enum PairingState: Equatable {
    case idle
    case discovering           // or .scanning for QR flow
    case connecting
    case authenticating
    case challengeReceived
    case awaitingApproval(countdown: Int)
    case paired
    case connected
    case failed(String)
    case disconnected

    public static func == (lhs: PairingState, rhs: PairingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.discovering, .discovering),
             (.connecting, .connecting), (.authenticating, .authenticating),
             (.challengeReceived, .challengeReceived), (.paired, .paired),
             (.connected, .connected), (.disconnected, .disconnected):
            return true
        case (.awaitingApproval(let l), .awaitingApproval(let r)):
            return l == r
        case (.failed(let l), .failed(let r)):
            return l == r
        default:
            return false
        }
    }
}

@Observable @MainActor
class OpenClawAltViewModel {
    var methodCards: [OpenClawAltMethodCard] = [
        OpenClawAltMethodCard(id: "tlan", name: "Trusted LAN Pairing", tagline: "Automatic discovery over Wi-Fi", securityLevel: .veryHigh, estimatedSetupTime: "~1 min", isRecommended: true),
        OpenClawAltMethodCard(id: "pc", name: "Pairing Code", tagline: "Enter an 8-digit code from your Mac", securityLevel: .high, estimatedSetupTime: "~30 sec"),
        OpenClawAltMethodCard(id: "qr", name: "QR Code Pairing", tagline: "Scan a code with your camera", securityLevel: .high, estimatedSetupTime: "~15 sec"),
        OpenClawAltMethodCard(id: "mt", name: "Manual Token", tagline: "Copy and paste a secure token", securityLevel: .high, estimatedSetupTime: "~1 min"),
        OpenClawAltMethodCard(id: "la", name: "Local Approval", tagline: "One-tap approval on your Mac", securityLevel: .medium, estimatedSetupTime: "~30 sec")
    ]
}

struct OpenClawAltMethodCard: Identifiable {
    let id: String
    let name: String
    let tagline: String
    let securityLevel: ALTSecurityLevel
    let estimatedSetupTime: String
    var isRecommended: Bool = false
}

enum ALTSecurityLevel: String {
    case medium = "Medium Security", high = "High Security", veryHigh = "Very High Security"
}
