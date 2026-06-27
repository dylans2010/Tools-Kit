import SwiftUI
import Observation

@MainActor @Observable
class ManualTokenViewModel {
    var host: String = ""
    var port: String = "18789"
    var token: String = ""
    var isValidating = false
    var error: String?
    var isSuccess = false

    func pair() async {
        isValidating = true
        error = nil

        guard let portInt = Int(port) else {
            error = "Invalid port"
            isValidating = false
            return
        }

        do {
            let isValid = try await ManualTokenService.shared.validateToken(token, host: host, port: portInt)
            if isValid {
                let deviceID = "iphone-\(UUID().uuidString.prefix(4))"
                OpenClawSecureStore.shared.saveToken(token, for: deviceID)

                let device = OpenClawDevice(
                    id: deviceID,
                    name: "Manual Gateway (\(host))",
                    host: host,
                    port: portInt,
                    lastConnected: Date(),
                    metadata: ["method": "manual_token"]
                )
                OpenClawDeviceRegistry.shared.register(device)

                isSuccess = true
                OpenClawLoggerService.shared.log(
                    level: .info,
                    category: .pairing,
                    title: "Manual Pairing Success",
                    description: "Saved token for \(host)"
                )
            }
        } catch {
            self.error = error.localizedDescription
            OpenClawLoggerService.shared.log(
                level: .error,
                category: .pairing,
                title: "Manual Pairing Failed",
                description: error.localizedDescription
            )
        }

        isValidating = false
    }
}
