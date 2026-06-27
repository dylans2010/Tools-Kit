import SwiftUI
import Observation

@MainActor @Observable
class PairingCodeViewModel {
    var code: String = ""
    var isValidating = false
    var error: String?
    var successToken: String?

    func validate(gatewayURL: URL) async {
        isValidating = true
        error = nil

        do {
            let token = try await PairingCodeService.shared.validateCode(code, gatewayURL: gatewayURL)
            self.successToken = token

            let deviceID = "iphone-\(UUID().uuidString.prefix(4))"
            OpenClawSecureStore.shared.saveToken(token, for: deviceID)

            let device = OpenClawDevice(
                id: deviceID,
                name: "Gateway (\(gatewayURL.host ?? "unknown"))",
                host: gatewayURL.host ?? "",
                port: gatewayURL.port ?? 18789,
                lastConnected: Date(),
                metadata: ["method": "pairing_code"]
            )
            OpenClawDeviceRegistry.shared.register(device)

            OpenClawLoggerService.shared.log(
                level: .info,
                category: .pairing,
                title: "Pairing Code Validated",
                description: "Trust established via one-time code"
            )
        } catch {
            self.error = error.localizedDescription
            OpenClawLoggerService.shared.log(
                level: .error,
                category: .pairing,
                title: "Pairing Code Failed",
                description: error.localizedDescription
            )
        }

        isValidating = false
    }
}
