import Foundation
import Observation
import Network

@Observable @MainActor
public final class LAPairingViewModel {
    public var state: PairingState = .idle

    public init() {}

    public func startPairing(host: String, port: Int) async {
        state = .connecting
        // Implementation for starting local approval pairing...
    }

    public func requestAccess(endpoint: NWEndpoint) async {
        state = .connecting
        let transport = OpenClawTransport()
        do {
            try await transport.connect(to: endpoint, using: .tcp)
            state = .awaitingApproval(countdown: 60)

            let info = await LADeviceInfoService.shared.getDeviceInfo()
            let request = PairingRequest(deviceName: info.deviceName)
            let data = try JSONEncoder().encode(request)
            try await transport.send(data)

            let responseData = try await transport.receive()
            let response = try JSONDecoder().decode(TLANMessage.self, from: responseData)

            if response.type == "APPROVAL_SUCCESS" {
                state = .paired
            } else {
                state = .failed("Access Denied")
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
        transport.disconnect()
    }
}
