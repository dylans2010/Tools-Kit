import SwiftUI
import Network

struct Diag_NetworkSecurityScanView: View {
    @State private var checks: [(String, String, SecurityLevel)] = []
    @State private var isScanning = false
    @State private var overallLevel: SecurityLevel = .unknown

    enum SecurityLevel {
        case secure, warning, risk, unknown

        var color: Color {
            switch self {
            case .secure: return .green
            case .warning: return .orange
            case .risk: return .red
            case .unknown: return .secondary
            }
        }

        var icon: String {
            switch self {
            case .secure: return "checkmark.shield.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .risk: return "xmark.shield.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }

    var body: some View {
        Form {
            Section("Network Security Scan") {
                VStack(spacing: 12) {
                    Image(systemName: overallLevel.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(overallLevel.color)
                    Text(overallTitle)
                        .font(.headline)
                    Text(overallSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Security Checks") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2.icon)
                            .foregroundStyle(check.2.color)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0).font(.subheadline.weight(.medium))
                            Text(check.1).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    runSecurityScan()
                } label: {
                    HStack {
                        if isScanning { ProgressView().scaleEffect(0.8) }
                        else { Image(systemName: "shield.lefthalf.filled") }
                        Text(isScanning ? "Scanning..." : "Run Security Scan")
                    }
                }
                .disabled(isScanning)
            }
        }
        .navigationTitle("Network Security")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runSecurityScan() }
    }

    private var overallTitle: String {
        switch overallLevel {
        case .secure: return "Network Secure"
        case .warning: return "Minor Concerns"
        case .risk: return "Security Risks Detected"
        case .unknown: return "Scanning..."
        }
    }

    private var overallSubtitle: String {
        switch overallLevel {
        case .secure: return "No network security issues detected"
        case .warning: return "Some network settings may need attention"
        case .risk: return "Network configuration has security concerns"
        case .unknown: return "Running security analysis..."
        }
    }

    private func runSecurityScan() {
        isScanning = true
        var results: [(String, String, SecurityLevel)] = []

        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var networkPath: NWPath?

        monitor.pathUpdateHandler = { path in
            networkPath = path
            monitor.cancel()
            semaphore.signal()
        }
        monitor.start(queue: DispatchQueue.global())
        _ = semaphore.wait(timeout: .now() + 5)

        if let path = networkPath {
            let isExpensive = path.isExpensive
            results.append(("Network Type", isExpensive ? "Cellular (expensive connection)" : "WiFi or wired", isExpensive ? .warning : .secure))

            let isConstrained = path.isConstrained
            results.append(("Low Data Mode", isConstrained ? "Enabled — limited connectivity" : "Disabled — full connectivity", isConstrained ? .warning : .secure))

            let usesVPN = path.usesInterfaceType(.other)
            results.append(("VPN Detection", usesVPN ? "VPN or tunnel detected" : "No VPN detected — traffic may not be encrypted", usesVPN ? .secure : .warning))
        }

        let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any]
        let hasProxy = proxySettings?["HTTPEnable"] as? Int == 1 || proxySettings?["HTTPSEnable"] as? Int == 1
        results.append(("HTTP Proxy", hasProxy ? "Proxy configured — traffic may be intercepted" : "No HTTP proxy configured", hasProxy ? .warning : .secure))

        if let dnsServers = getDNSServers() {
            let hasCustomDNS = !dnsServers.isEmpty
            let dnsStr = dnsServers.prefix(3).joined(separator: ", ")
            results.append(("DNS Servers", hasCustomDNS ? "DNS: \(dnsStr)" : "Default DNS", .secure))
        }

        testHTTPS { secure in
            DispatchQueue.main.async {
                results.append(("HTTPS Verification", secure ? "HTTPS connections verified successfully" : "HTTPS test failed — possible MITM", secure ? .secure : .risk))

                checks = results
                let riskCount = results.filter { $0.2 == .risk }.count
                let warningCount = results.filter { $0.2 == .warning }.count
                overallLevel = riskCount > 0 ? .risk : warningCount > 1 ? .warning : .secure
                isScanning = false
            }
        }
    }

    private func testHTTPS(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://www.apple.com") else {
            completion(false); return
        }
        URLSession.shared.dataTask(with: url) { _, response, error in
            let success = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
            completion(success)
        }.resume()
    }

    private func getDNSServers() -> [String]? {
        var servers: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        freeifaddrs(ifaddr)
        if let resolv = try? String(contentsOfFile: "/etc/resolv.conf", encoding: .utf8) {
            for line in resolv.components(separatedBy: "\n") {
                if line.hasPrefix("nameserver ") {
                    servers.append(String(line.dropFirst(11)).trimmingCharacters(in: .whitespaces))
                }
            }
        }
        return servers.isEmpty ? nil : servers
    }
}
