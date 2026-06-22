import SwiftUI
import CoreTelephony
import Network

struct Diag_CellularInfoView: View {
    @State private var carriers: [CarrierInfo] = []
    @State private var radioTech: String = "Unknown"
    @State private var isConnected = false
    @State private var dataUsage: (sent: UInt64, received: UInt64) = (0, 0)

    struct CarrierInfo: Identifiable {
        let id = UUID()
        let name: String
        let country: String
        let isoCountryCode: String
        let mobileCountryCode: String
        let mobileNetworkCode: String
        let allowsVOIP: Bool
    }

    var body: some View {
        Form {
            Section("Connection") {
                HStack {
                    Image(systemName: isConnected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        .font(.title2)
                        .foregroundStyle(isConnected ? .green : .red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isConnected ? "Cellular Connected" : "No Cellular")
                            .font(.headline)
                        Text(radioTech)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if !carriers.isEmpty {
                ForEach(carriers, id: \.id) { carrier in
                    Section("Carrier: \(carrier.name)") {
                        LabeledContent("Name") { Text(carrier.name) }
                        LabeledContent("Country") { Text(carrier.country) }
                        LabeledContent("ISO Code") { Text(carrier.isoCountryCode.uppercased()) }
                        LabeledContent("MCC") { Text(carrier.mobileCountryCode).monospacedDigit() }
                        LabeledContent("MNC") { Text(carrier.mobileNetworkCode).monospacedDigit() }
                        LabeledContent("VoIP") {
                            Text(carrier.allowsVOIP ? "Supported" : "Not Supported")
                                .foregroundStyle(carrier.allowsVOIP ? .green : .secondary)
                        }
                    }
                }
            }

            Section("Radio Access Technology") {
                LabeledContent("Current") {
                    Text(radioTech)
                        .foregroundStyle(radioTechColor)
                }
                LabeledContent("Generation") { Text(radioGeneration) }
                LabeledContent("Max Speed (Theoretical)") {
                    Text(theoreticalMaxSpeed)
                        .font(.caption)
                }
            }

            Section("Data Usage (This Session)") {
                let stats = getCellularStats()
                LabeledContent("Sent") { Text(formatBytes(stats.sent)).monospacedDigit() }
                LabeledContent("Received") { Text(formatBytes(stats.received)).monospacedDigit() }
                LabeledContent("Total") { Text(formatBytes(stats.sent + stats.received)).monospacedDigit() }
            }

            Section("SIM Info") {
                LabeledContent("SIM Slots") {
                    let info = CTTelephonyNetworkInfo()
                    Text("\(info.serviceSubscriberCellularProviders?.count ?? 0)")
                }
                LabeledContent("Dual SIM") {
                    let info = CTTelephonyNetworkInfo()
                    Text((info.serviceSubscriberCellularProviders?.count ?? 0) > 1 ? "Yes" : "Single SIM")
                }
                LabeledContent("eSIM") { Text("Check in Settings").foregroundStyle(.secondary) }
            }

            Section {
                Button {
                    refreshInfo()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                }
            }
        }
        .navigationTitle("Cellular Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshInfo() }
    }

    private var radioTechColor: Color {
        if radioTech.contains("NR") { return .blue }
        if radioTech.contains("LTE") { return .green }
        if radioTech.contains("WCDMA") || radioTech.contains("HSDPA") { return .orange }
        return .secondary
    }

    private var radioGeneration: String {
        if radioTech.contains("NR") { return "5G" }
        if radioTech.contains("LTE") { return "4G LTE" }
        if radioTech.contains("WCDMA") || radioTech.contains("HSDPA") || radioTech.contains("HSUPA") { return "3G" }
        if radioTech.contains("EDGE") || radioTech.contains("GPRS") { return "2G" }
        return "Unknown"
    }

    private var theoreticalMaxSpeed: String {
        if radioTech.contains("NR") { return "Up to 10 Gbps" }
        if radioTech.contains("LTE") { return "Up to 1 Gbps" }
        if radioTech.contains("HSDPA") { return "Up to 42 Mbps" }
        if radioTech.contains("WCDMA") { return "Up to 2 Mbps" }
        if radioTech.contains("EDGE") { return "Up to 384 Kbps" }
        return "Unknown"
    }

    private func refreshInfo() {
        let networkInfo = CTTelephonyNetworkInfo()

        // Get carriers
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            carriers = providers.compactMap { _, provider in
                guard let name = provider.carrierName else { return nil }
                return CarrierInfo(
                    name: name,
                    country: Locale.current.localizedString(forRegionCode: provider.isoCountryCode ?? "") ?? provider.isoCountryCode ?? "Unknown",
                    isoCountryCode: provider.isoCountryCode ?? "N/A",
                    mobileCountryCode: provider.mobileCountryCode ?? "N/A",
                    mobileNetworkCode: provider.mobileNetworkCode ?? "N/A",
                    allowsVOIP: provider.allowsVOIP
                )
            }
        }

        // Get radio access technology
        if let techDict = networkInfo.serviceCurrentRadioAccessTechnology {
            let tech = techDict.values.first ?? "Unknown"
            radioTech = tech.replacingOccurrences(of: "CTRadioAccessTechnology", with: "")
        }

        // Check connection
        let monitor = NWPathMonitor(requiredInterfaceType: .cellular)
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                isConnected = path.status == .satisfied
                monitor.cancel()
            }
        }
        monitor.start(queue: .global(qos: .utility))
    }

    private func getCellularStats() -> (sent: UInt64, received: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }

        var sent: UInt64 = 0
        var received: UInt64 = 0
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            if name.hasPrefix("pdp_ip"), let data = addr.pointee.ifa_data {
                let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                sent += UInt64(networkData.ifi_obytes)
                received += UInt64(networkData.ifi_ibytes)
            }
            ptr = addr.pointee.ifa_next
        }
        return (sent, received)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
