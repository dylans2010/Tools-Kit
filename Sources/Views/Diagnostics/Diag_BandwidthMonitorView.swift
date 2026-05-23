import SwiftUI

struct Diag_BandwidthMonitorView: View {
    @State private var isMonitoring = false
    @State private var bytesSent: UInt64 = 0
    @State private var bytesReceived: UInt64 = 0
    @State private var prevBytesSent: UInt64 = 0
    @State private var prevBytesReceived: UInt64 = 0
    @State private var uploadRate: Double = 0
    @State private var downloadRate: Double = 0
    @State private var peakUpload: Double = 0
    @State private var peakDownload: Double = 0
    @State private var samples: [BandwidthSample] = []
    @State private var timer: Timer?

    struct BandwidthSample: Identifiable {
        let id = UUID()
        let timestamp: Date
        let upload: Double
        let download: Double
    }

    var body: some View {
        Form {
            Section("Current Rate") {
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text(formatRate(uploadRate))
                            .font(.headline.monospacedDigit())
                        Text("Upload")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text(formatRate(downloadRate))
                            .font(.headline.monospacedDigit())
                        Text("Download")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
            }

            Section("Total Transfer") {
                LabeledContent("Bytes Sent") {
                    Text(formatBytes(bytesSent))
                        .monospacedDigit()
                }
                LabeledContent("Bytes Received") {
                    Text(formatBytes(bytesReceived))
                        .monospacedDigit()
                }
                LabeledContent("Peak Upload") {
                    Text(formatRate(peakUpload))
                        .monospacedDigit()
                        .foregroundStyle(.blue)
                }
                LabeledContent("Peak Download") {
                    Text(formatRate(peakDownload))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
            }

            if !samples.isEmpty {
                Section("Recent Activity (\(samples.count) samples)") {
                    ForEach(samples.suffix(10)) { sample in
                        HStack {
                            Text(sample.timestamp, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack(spacing: 12) {
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.up")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                    Text(formatRate(sample.upload))
                                        .font(.caption.monospacedDigit())
                                }
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.down")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                    Text(formatRate(sample.download))
                                        .font(.caption.monospacedDigit())
                                }
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }

                if isMonitoring {
                    Button("Reset Statistics") {
                        peakUpload = 0
                        peakDownload = 0
                        samples = []
                    }
                }
            }
        }
        .navigationTitle("Bandwidth Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        isMonitoring = true
        let stats = getNetworkStats()
        prevBytesSent = stats.sent
        prevBytesReceived = stats.received
        bytesSent = stats.sent
        bytesReceived = stats.received

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let current = getNetworkStats()
            let sentDiff = current.sent >= prevBytesSent ? current.sent - prevBytesSent : 0
            let recvDiff = current.received >= prevBytesReceived ? current.received - prevBytesReceived : 0

            uploadRate = Double(sentDiff)
            downloadRate = Double(recvDiff)
            bytesSent = current.sent
            bytesReceived = current.received
            prevBytesSent = current.sent
            prevBytesReceived = current.received

            if uploadRate > peakUpload { peakUpload = uploadRate }
            if downloadRate > peakDownload { peakDownload = downloadRate }

            samples.append(BandwidthSample(timestamp: Date(), upload: uploadRate, download: downloadRate))
            if samples.count > 60 { samples.removeFirst() }
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func getNetworkStats() -> (sent: UInt64, received: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }

        var totalSent: UInt64 = 0
        var totalReceived: UInt64 = 0
        var ptr: UnsafeMutablePointer<ifaddrs>? = first

        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            if name.hasPrefix("en") || name.hasPrefix("pdp_ip") || name.hasPrefix("lo") {
                if let data = addr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    totalSent += UInt64(networkData.ifi_obytes)
                    totalReceived += UInt64(networkData.ifi_ibytes)
                }
            }
            ptr = addr.pointee.ifa_next
        }
        return (totalSent, totalReceived)
    }

    private func formatRate(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 { return String(format: "%.0f B/s", bytesPerSecond) }
        if bytesPerSecond < 1024 * 1024 { return String(format: "%.1f KB/s", bytesPerSecond / 1024) }
        return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
