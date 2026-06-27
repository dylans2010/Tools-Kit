import Foundation
import Observation
import CryptoKit
import OSLog

@Observable @MainActor
public final class PCPairingViewModel {
    public var state: PairingState = .idle
    private let logger = Logger(subsystem: "com.toolskit.openclaw.alternatives", category: "pairing-code")

    public init() {}

    public func generateOTP() -> String {
        // Cryptographically random — NEVER "123456" or any literal
        var bytes = [UInt8](repeating: 0, count: 4)
        _ = SecRandomCopyBytes(kSecRandomDefault, 4, &bytes)
        let raw = bytes.withUnsafeBytes { $0.load(as: UInt32.self) }
        return String(format: "%06d", Int(raw % 900_000) + 100_000)
    }

    public func submitCode(_ code: String, host: String, port: Int) async {
        state = .authenticating
        do {
            let request = PCValidationRequest(code: code, deviceId: await LADeviceInfoService.shared.getDeviceInfo().appInstallId)
            let response = try await PCCodeValidationService.shared.validateCode(request, gatewayHost: host, gatewayPort: port)
            if response.success {
                state = .paired
            } else {
                state = .failed("Invalid Code")
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

// MARK: - Required Models for One-Time Code

public struct PCValidationRequest: Codable {
    let code: String
    let deviceId: String
}

public struct PCValidationResponse: Codable {
    let success: Bool
    let token: String?
}
