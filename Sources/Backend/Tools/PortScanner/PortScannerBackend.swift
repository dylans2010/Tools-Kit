import Foundation
import Network

struct PortResult: Identifiable {
    let id = UUID()
    let port: UInt16
    let service: String
    var status: Status = .pending

    enum Status { case pending, open, closed, timeout }
}

@MainActor
final class PortScannerBackend: ObservableObject {
    @Published var host = "scanme.nmap.org"
    @Published var results: [PortResult] = []
    @Published var isScanning = false
    @Published var progress: Double = 0

    static let commonPorts: [(UInt16, String)] = [
        (21, "FTP"), (22, "SSH"), (23, "Telnet"), (25, "SMTP"),
        (53, "DNS"), (80, "HTTP"), (110, "POP3"), (143, "IMAP"),
        (443, "HTTPS"), (465, "SMTPS"), (587, "SMTP Alt"),
        (993, "IMAPS"), (995, "POP3S"), (3306, "MySQL"),
        (5432, "PostgreSQL"), (6379, "Redis"), (8080, "HTTP Alt"),
        (8443, "HTTPS Alt"), (27017, "MongoDB"), (3389, "RDP")
    ]

    var openCount: Int { results.filter { $0.status == .open }.count }

    func scan() {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isScanning else { return }

        results = Self.commonPorts.map { PortResult(port: $0.0, service: $0.1) }
        isScanning = true
        progress = 0

        Task {
            let total = Double(results.count)
            for i in results.indices {
                await checkPort(index: i, host: trimmed)
                progress = Double(i + 1) / total
            }
            isScanning = false
        }
    }

    func cancel() {
        isScanning = false
    }

    private func checkPort(index: Int, host: String) async {
        let port = results[index].port
        return await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(integerLiteral: port),
                using: .tcp
            )
            var resolved = false

            connection.stateUpdateHandler = { [weak self] state in
                guard !resolved else { return }
                switch state {
                case .ready:
                    resolved = true
                    connection.cancel()
                    Task { @MainActor in
                        self?.results[index].status = .open
                        continuation.resume()
                    }
                case .failed:
                    resolved = true
                    connection.cancel()
                    Task { @MainActor in
                        self?.results[index].status = .closed
                        continuation.resume()
                    }
                default: break
                }
            }
            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + 4) {
                guard !resolved else { return }
                resolved = true
                connection.cancel()
                Task { @MainActor in
                    self.results[index].status = .timeout
                    continuation.resume()
                }
            }
        }
    }
}
