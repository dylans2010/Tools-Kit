import SwiftUI
import Network

/// Real traceroute. The previous version hardcoded four hops
/// (192.168.1.1 / 10.0.0.1 / 172.217.1.1 / 8.8.8.8 with fixed RTTs).
/// This version sends real ICMP probes with increasing TTL, like the
/// main Traceroute tool, and reports the responder address and RTT
/// for each hop — or a timeout where nothing responds.
struct Diag_NetworkTraceRouteView: View {
    @State private var targetHost = "8.8.8.8"
    @State private var hops: [AdvTraceHop] = []
    @State private var isTracing = false

    struct AdvTraceHop: Identifiable {
        let id = UUID()
        let hop: Int
        let ip: String
        let rtt: String
    }

    var body: some View {
        List {
            Section("Target") {
                HStack {
                    TextField("Host or IP", text: $targetHost)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        if isTracing { isTracing = false } else { startTrace() }
                    } label: {
                        Image(systemName: isTracing ? "stop.fill" : "play.fill")
                    }
                    .disabled(targetHost.isEmpty)
                }
            }
            Section("Hop Analysis") {
                if hops.isEmpty && !isTracing {
                    Text("No hops yet — run a trace to measure the real route.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(hops) { hop in
                    HopRow(hop: hop.hop, ip: hop.ip, rtt: hop.rtt)
                }
                if isTracing {
                    HStack { ProgressView(); Text("Tracing…").font(.caption).foregroundStyle(.secondary) }
                }
            }
            Section {
                Text("iOS sandboxing can block raw ICMP sockets on some networks; a hop that shows '* * *' is a real timeout on this network, not a stored value.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Advanced TraceRoute")
    }

    private func startTrace() {
        isTracing = true
        hops = []
        let host = targetHost
        DispatchQueue.global(qos: .userInitiated).async {
            for ttl in 1...30 {
                guard self.isTracing else { break }
                let start = CFAbsoluteTimeGetCurrent()
                let address = pingWithTTL(host: host, ttl: ttl)
                let elapsed = CFAbsoluteTimeGetCurrent() - start
                let hop: AdvTraceHop
                if let address {
                    hop = AdvTraceHop(hop: ttl, ip: address, rtt: String(format: "%.1fms", elapsed * 1000))
                } else {
                    hop = AdvTraceHop(hop: ttl, ip: "*", rtt: "* * *")
                }
                DispatchQueue.main.async { self.hops.append(hop) }
                if address == host || resolvedAddress(for: host) == address { break }
                Thread.sleep(forTimeInterval: 0.1)
            }
            DispatchQueue.main.async { self.isTracing = false }
        }
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
        guard inet_pton(AF_INET, host, &addr.sin_addr) == 1 else {
            // Hostname: resolve it first, then retry with the IP.
            guard let resolved = resolvedAddress(for: host) else { return nil }
            return pingWithTTL(host: resolved, ttl: ttl)
        }
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

struct HopRow: View {
    let hop: Int
    let ip: String
    let rtt: String
    var body: some View {
        HStack {
            Text("\(hop)")
                .font(.caption.bold())
                .frame(width: 20)
            Text(ip)
                .font(.subheadline.monospaced())
            Spacer()
            Text(rtt)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
