import SwiftUI
import Observation

@MainActor @Observable
class LocalApprovalViewModel {
    var discoveredServices: [OpenClawDiscoveredService] {
        OpenClawDiscoveryService.shared.discoveredServices
    }
    var isWaiting = false
    var status: String = "Idle"
    var error: String?

    func startDiscovery() {
        OpenClawDiscoveryService.shared.startDiscovery()
    }

    func requestApproval(from service: OpenClawDiscoveredService) async {
        isWaiting = true
        status = "Waiting for Mac approval..."
        error = nil

        do {
            let token = try await LocalApprovalService.shared.initiateApproval(service: service)
            let deviceID = "iphone-\(UIDevice.current.identifierForVendor?.uuidString.prefix(4) ?? "unknown")"
            OpenClawSecureStore.shared.saveToken(token, for: deviceID)

            let device = OpenClawDevice(
                id: deviceID,
                name: service.name,
                host: service.ipAddress ?? service.host,
                port: service.port,
                lastConnected: Date(),
                metadata: ["method": "local_approval"]
            )
            OpenClawDeviceRegistry.shared.register(device)

            status = "Approved!"
            OpenClawLoggerService.shared.log(
                level: .info,
                category: .pairing,
                title: "Local Approval Success",
                description: "Approved by \(service.name)"
            )
        } catch {
            self.error = error.localizedDescription
            status = "Denied or Failed"
            OpenClawLoggerService.shared.log(
                level: .error,
                category: .pairing,
                title: "Local Approval Error",
                description: error.localizedDescription
            )
        }
        isWaiting = false
    }
}
