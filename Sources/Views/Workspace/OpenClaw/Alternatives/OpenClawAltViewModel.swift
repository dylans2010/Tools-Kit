import Foundation
import Observation

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
