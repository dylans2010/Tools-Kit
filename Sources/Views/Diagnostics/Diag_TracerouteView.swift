import SwiftUI
import Network

struct Diag_TracerouteView: View {
    @State private var targetHost: String = "8.8.8.8"
    @State private var hops: [TracerouteHop] = []
    @State private var isTracing = false
    @State private var currentHop = 0
    @State private var maxHops = 30

    struct TracerouteHop: Identifiable {
        let id = UUID()
        let hopNumber: Int
        let address: String
        let rtt: TimeInterval
        let status: HopStatus
    }

    enum HopStatus {
        case reached, timeout, final
    }

    var body: some View {
        Form {
            Section("Target") {
                HStack {
                    TextField("Host or IP", text: $targetHost)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Button {
                        if isTracing { stopTrace() } else { startTrace() }
                    } label: {
                        Image(systemName: isTracing ? "stop.fill" : "play.fill")
                    }
                    .disabled(targetHost.isEmpty)
                }
            }

            if isTracing {
                Section {
                    HStack {
                        ProgressView()
                        Text("Tracing hop \(currentHop)...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !hops.isEmpty {
                Section("Route (\(hops.count) hops)") {
                    ForEach(hops, id: \.id) { hop in
                        HStack {
                            Text("\(hop.hopNumber)")
                                .font(.caption.monospacedDigit())
                                .frame(width: 24, alignment: .trailing)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(hop.address)
                                    .font(.system(.caption, design: .monospaced))
                                if hop.status == .timeout {
                                    Text("Request timed out")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            Spacer()
                            if hop.status != .timeout {
                                Text(String(format: "%.1f ms", hop.rtt * 1000))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(rttColor(hop.rtt))
                            } else {
                                Text("* * *")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                Section("Statistics") {
                    let validHops = hops.filter { $0.status != .timeout }
                    LabeledContent("Total Hops") { Text("\(hops.count)") }
                    LabeledContent("Timeouts") { Text("\(hops.filter { $0.status == .timeout }.count)") }
                    if !validHops.isEmpty {
                        LabeledContent("Avg RTT") {
                            let avg = validHops.map(\.rtt).reduce(0, +) / Double(validHops.count)
                            Text(String(format: "%.1f ms", avg * 1000)).monospacedDigit()
                        }
                        LabeledContent("Max RTT") {
                            let max = validHops.map(\.rtt).max() ?? 0
                            Text(String(format: "%.1f ms", max * 1000)).monospacedDigit()
                        }
                    }
                }
            }

            Section("Presets") {
                ForEach(["8.8.8.8", "1.1.1.1", "apple.com", "google.com"], id: \.self) { host in
                    Button {
                        targetHost = host
                    } label: {
                        HStack {
                            Text(host)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Traceroute")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func rttColor(_ rtt: TimeInterval) -> Color {
        let ms = rtt * 1000
        if ms < 50 { return .green }
        if ms < 150 { return .yellow }
        return .red
    }

    private func startTrace() {
        isTracing = true
        hops = []
        currentHop = 0

        DispatchQueue.global(qos: .userInitiated).async {
            for ttl in 1...maxHops {
                guard self.isTracing else { break }
                DispatchQueue.main.async { self.currentHop = ttl }

                let start = CFAbsoluteTimeGetCurrent()
                let result = pingWithTTL(host: targetHost, ttl: ttl)
                let elapsed = CFAbsoluteTimeGetCurrent() - start

                let hop: TracerouteHop
                if let address = result {
                    let isFinal = address == targetHost || resolvedAddress(for: targetHost) == address
                    hop = TracerouteHop(hopNumber: ttl, address: address, rtt: elapsed, status: isFinal ? .final : .reached)
                } else {
                    hop = TracerouteHop(hopNumber: ttl, address: "*", rtt: 0, status: .timeout)
                }

                DispatchQueue.main.async {
                    self.hops.append(hop)
                }

                if hop.status == .final { break }
                Thread.sleep(forTimeInterval: 0.1)
            }
            DispatchQueue.main.async { self.isTracing = false }
        }
    }

    private func stopTrace() {
        isTracing = false
    }

    private func pingWithTTL(host: String, ttl: Int) -> String? {
        let socketFd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
        guard socketFd >= 0 else { return nil }
        defer { close(socketFd) }

        var ttlValue = Int32(ttl)
        setsockopt(socketFd, IPPROTO_IP, IP_TTL, &ttlValue, socklen_t(MemoryLayout<Int32>.size))

        var timeout = timeval(tv_sec: 2, tv_usec: 0)
        setsockopt(socketFd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(33434 + ttl).bigEndian
        inet_pton(AF_INET, host, &addr.sin_addr)

        let message: [UInt8] = [0x08, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01]
        _ = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                sendto(socketFd, message, message.count, 0, sockPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        var response = [UInt8](repeating: 0, count: 512)
        var fromAddr = sockaddr_in()
        var fromLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        let received = withUnsafeMutablePointer(to: &fromAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                recvfrom(socketFd, &response, response.count, 0, sockPtr, &fromLen)
            }
        }

        guard received > 0 else { return nil }

        var ipStr = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        inet_ntop(AF_INET, &fromAddr.sin_addr, &ipStr, socklen_t(INET_ADDRSTRLEN))
        return String(cString: ipStr)
    }

    private func resolvedAddress(for host: String) -> String? {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &result) == 0, let res = result else { return nil }
        defer { freeaddrinfo(result) }
        let addr = res.pointee.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
        var ipStr = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        var sinAddr = addr.sin_addr
        inet_ntop(AF_INET, &sinAddr, &ipStr, socklen_t(INET_ADDRSTRLEN))
        return String(cString: ipStr)
    }
}
