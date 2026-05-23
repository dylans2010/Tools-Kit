import SwiftUI
import Network

struct Diag_PortScannerView: View {
    @State private var host: String = "127.0.0.1"
    @State private var startPort: String = "1"
    @State private var endPort: String = "1024"
    @State private var results: [PortResult] = []
    @State private var isScanning = false
    @State private var progress: Double = 0
    @State private var openCount = 0
    @State private var scannedCount = 0

    struct PortResult: Identifiable {
        let id = UUID()
        let port: UInt16
        let status: PortStatus
        let service: String
    }

    enum PortStatus {
        case open, closed, filtered
        var label: String {
            switch self {
            case .open: return "Open"
            case .closed: return "Closed"
            case .filtered: return "Filtered"
            }
        }
        var color: Color {
            switch self {
            case .open: return .green
            case .closed: return .red
            case .filtered: return .orange
            }
        }
    }

    var body: some View {
        Form {
            Section("Target") {
                TextField("Host / IP", text: $host)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                HStack {
                    TextField("Start Port", text: $startPort)
                        .keyboardType(.numberPad)
                    Text("–")
                    TextField("End Port", text: $endPort)
                        .keyboardType(.numberPad)
                }
            }

            Section {
                Button {
                    if isScanning { stopScan() } else { startScan() }
                } label: {
                    HStack {
                        Image(systemName: isScanning ? "stop.circle.fill" : "magnifyingglass.circle.fill")
                        Text(isScanning ? "Stop Scan" : "Start Scan")
                    }
                }

                if isScanning {
                    ProgressView(value: progress)
                    Text("Scanned \(scannedCount) ports, \(openCount) open")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !results.isEmpty {
                Section("Open Ports (\(results.filter { $0.status == .open }.count))") {
                    ForEach(results.filter { $0.status == .open }) { result in
                        HStack {
                            Text("\(result.port)")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 60, alignment: .leading)
                            Text(result.service)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(result.status.label)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(result.status.color)
                        }
                    }
                }
            }

            Section("Common Ports") {
                ForEach(commonPorts, id: \.0) { port, name in
                    HStack {
                        Text("\(port)")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 60, alignment: .leading)
                        Text(name)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Port Scanner")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var commonPorts: [(UInt16, String)] {
        [(22, "SSH"), (80, "HTTP"), (443, "HTTPS"), (8080, "HTTP Alt"), (3000, "Dev Server"), (5432, "PostgreSQL"), (3306, "MySQL"), (6379, "Redis")]
    }

    private func startScan() {
        guard let start = UInt16(startPort), let end = UInt16(endPort), start <= end else { return }
        isScanning = true
        results = []
        openCount = 0
        scannedCount = 0
        progress = 0
        let totalPorts = Int(end - start + 1)

        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()
            let semaphore = DispatchSemaphore(value: 50)

            for port in start...end {
                guard self.isScanning else { break }
                group.enter()
                semaphore.wait()

                let connection = NWConnection(host: NWEndpoint.Host(self.host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        let result = PortResult(port: port, status: .open, service: self.serviceName(for: port))
                        DispatchQueue.main.async {
                            self.results.append(result)
                            self.openCount += 1
                            self.scannedCount += 1
                            self.progress = Double(self.scannedCount) / Double(totalPorts)
                        }
                        connection.cancel()
                        semaphore.signal()
                        group.leave()
                    case .failed, .cancelled:
                        DispatchQueue.main.async {
                            self.scannedCount += 1
                            self.progress = Double(self.scannedCount) / Double(totalPorts)
                        }
                        semaphore.signal()
                        group.leave()
                    default:
                        break
                    }
                }
                connection.start(queue: .global(qos: .utility))

                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2) {
                    if connection.state != .ready && connection.state != .cancelled {
                        connection.cancel()
                    }
                }
            }

            group.notify(queue: .main) {
                self.isScanning = false
                self.progress = 1.0
            }
        }
    }

    private func stopScan() {
        isScanning = false
    }

    private func serviceName(for port: UInt16) -> String {
        switch port {
        case 20: return "FTP Data"
        case 21: return "FTP"
        case 22: return "SSH"
        case 23: return "Telnet"
        case 25: return "SMTP"
        case 53: return "DNS"
        case 80: return "HTTP"
        case 110: return "POP3"
        case 143: return "IMAP"
        case 443: return "HTTPS"
        case 993: return "IMAPS"
        case 995: return "POP3S"
        case 3306: return "MySQL"
        case 5432: return "PostgreSQL"
        case 6379: return "Redis"
        case 8080: return "HTTP Alt"
        case 8443: return "HTTPS Alt"
        default: return "Unknown"
        }
    }
}
