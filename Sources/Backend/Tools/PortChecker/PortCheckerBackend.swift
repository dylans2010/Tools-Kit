import Foundation
import Network

class PortCheckerBackend: ObservableObject {
    @Published var host = "google.com"
    @Published var port = "443"
    @Published var status = ""
    @Published var isChecking = false
    @Published var color = "gray"

    func check() {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty, let portInt = Int(port), portInt > 0 && portInt < 65536 else {
            status = "Invalid host or port"
            color = "red"
            return
        }

        isChecking = true
        status = "Checking \(trimmedHost):\(portInt)..."
        color = "gray"

        let connection = NWConnection(host: NWEndpoint.Host(trimmedHost), port: NWEndpoint.Port(integerLiteral: UInt16(portInt)), using: .tcp)

        connection.stateUpdateHandler = { state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self.status = "Port \(portInt) is OPEN"
                    self.color = "green"
                    self.isChecking = false
                    connection.cancel()
                case .failed(let error):
                    self.status = "Port \(portInt) is CLOSED or Filtered"
                    self.color = "red"
                    self.isChecking = false
                case .waiting(let error):
                    // Could still be connecting, but we'll timeout after 5 seconds
                    break
                default:
                    break
                }
            }
        }

        connection.start(queue: .global())

        // Timeout after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.isChecking {
                connection.cancel()
                self.isChecking = false
                self.status = "Connection timed out (Likely closed/filtered)"
                self.color = "orange"
            }
        }
    }
}
