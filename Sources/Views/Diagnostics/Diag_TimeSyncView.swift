import SwiftUI

struct Diag_TimeSyncView: View {
    @State private var localTime: Date = Date()
    @State private var ntpOffset: TimeInterval?
    @State private var isChecking = false
    @State private var ntpServer: String = "time.apple.com"
    @State private var lastCheckTime: Date?
    @State private var checkHistory: [NTPCheck] = []
    @State private var timer: Timer?

    struct NTPCheck: Identifiable {
        let id = UUID()
        let timestamp: Date
        let server: String
        let offset: TimeInterval?
        let roundTrip: TimeInterval
        let success: Bool
    }

    var body: some View {
        Form {
            Section("Device Clock") {
                LabeledContent("Local Time") {
                    Text(localTime, style: .time)
                        .monospacedDigit()
                }
                LabeledContent("Date") {
                    Text(localTime, style: .date)
                }
                LabeledContent("Timezone") {
                    Text(TimeZone.current.identifier)
                }
                LabeledContent("UTC Offset") {
                    Text(formatUTCOffset())
                }
                LabeledContent("Auto Set") {
                    Text("Managed by iOS")
                        .foregroundStyle(.secondary)
                }
            }

            Section("NTP Sync") {
                HStack {
                    TextField("NTP Server", text: $ntpServer)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        checkNTP()
                    } label: {
                        if isChecking {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isChecking)
                }

                if let offset = ntpOffset {
                    LabeledContent("Clock Offset") {
                        Text(String(format: "%+.3f ms", offset * 1000))
                            .monospacedDigit()
                            .foregroundStyle(abs(offset) < 0.1 ? .green : .orange)
                    }
                    LabeledContent("Accuracy") {
                        Text(abs(offset) < 0.01 ? "Excellent" : (abs(offset) < 0.1 ? "Good" : "Needs Sync"))
                            .foregroundStyle(abs(offset) < 0.01 ? .green : (abs(offset) < 0.1 ? .yellow : .red))
                    }
                }

                if let last = lastCheckTime {
                    LabeledContent("Last Check") {
                        Text(last, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("NTP Servers") {
                ForEach(["time.apple.com", "pool.ntp.org", "time.google.com", "time.cloudflare.com"], id: \.self) { server in
                    Button {
                        ntpServer = server
                        checkNTP()
                    } label: {
                        HStack {
                            Text(server)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.right.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !checkHistory.isEmpty {
                Section("Check History") {
                    ForEach(checkHistory, id: \.id) { check in
                        HStack {
                            Image(systemName: check.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(check.success ? .green : .red)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(check.server)
                                    .font(.caption)
                                Text(check.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            if let offset = check.offset {
                                Text(String(format: "%+.1fms", offset * 1000))
                                    .font(.caption.monospacedDigit())
                            }
                            Text(String(format: "RTT: %.0fms", check.roundTrip * 1000))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("System Clocks") {
                LabeledContent("System Uptime") {
                    Text(formatUptime(ProcessInfo.processInfo.systemUptime))
                        .monospacedDigit()
                }
                LabeledContent("Boot Time") {
                    let bootTime = Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)
                    Text(bootTime, style: .date)
                }
                LabeledContent("Monotonic Clock") {
                    Text(String(format: "%.3f s", CACurrentMediaTime()))
                        .monospacedDigit()
                }
            }
        }
        .navigationTitle("Time Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                localTime = Date()
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    private func formatUTCOffset() -> String {
        let offset = TimeZone.current.secondsFromGMT()
        let hours = offset / 3600
        let minutes = abs(offset % 3600) / 60
        return String(format: "UTC%+d:%02d", hours, minutes)
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if d > 0 { return "\(d)d \(h)h \(m)m" }
        return "\(h)h \(m)m \(s)s"
    }

    private func checkNTP() {
        isChecking = true
        let server = ntpServer
        let startTime = CFAbsoluteTimeGetCurrent()

        DispatchQueue.global(qos: .userInitiated).async {
            let offset = performNTPQuery(server: server)
            let roundTrip = CFAbsoluteTimeGetCurrent() - startTime

            DispatchQueue.main.async {
                self.ntpOffset = offset
                self.lastCheckTime = Date()
                self.isChecking = false
                self.checkHistory.insert(
                    NTPCheck(timestamp: Date(), server: server, offset: offset, roundTrip: roundTrip, success: offset != nil),
                    at: 0
                )
                if self.checkHistory.count > 20 { self.checkHistory.removeLast() }
            }
        }
    }

    private func performNTPQuery(server: String) -> TimeInterval? {
        let socketFd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socketFd >= 0 else { return nil }
        defer { close(socketFd) }

        var timeout = timeval(tv_sec: 5, tv_usec: 0)
        setsockopt(socketFd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_DGRAM
        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(server, "123", &hints, &result) == 0, let res = result else { return nil }
        defer { freeaddrinfo(result) }

        // NTP packet: 48 bytes, LI=0, VN=4, Mode=3 (client)
        var packet = [UInt8](repeating: 0, count: 48)
        packet[0] = 0x23 // LI=0, VN=4, Mode=3

        let t1 = Date().timeIntervalSince1970 + 2208988800 // NTP epoch offset
        let seconds = UInt32(t1)
        packet[40] = UInt8((seconds >> 24) & 0xFF)
        packet[41] = UInt8((seconds >> 16) & 0xFF)
        packet[42] = UInt8((seconds >> 8) & 0xFF)
        packet[43] = UInt8(seconds & 0xFF)

        let sent = sendto(socketFd, &packet, packet.count, 0, res.pointee.ai_addr, res.pointee.ai_addrlen)
        guard sent > 0 else { return nil }

        var response = [UInt8](repeating: 0, count: 48)
        let received = recv(socketFd, &response, response.count, 0)
        guard received >= 48 else { return nil }

        let t4 = Date().timeIntervalSince1970

        // Extract transmit timestamp (bytes 40-47)
        let txSeconds = UInt32(response[40]) << 24 | UInt32(response[41]) << 16 | UInt32(response[42]) << 8 | UInt32(response[43])
        let txFraction = UInt32(response[44]) << 24 | UInt32(response[45]) << 16 | UInt32(response[46]) << 8 | UInt32(response[47])
        let serverTime = Double(txSeconds) - 2208988800 + Double(txFraction) / Double(UInt32.max)

        return serverTime - t4
    }
}
