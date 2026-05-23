import SwiftUI
import CoreTelephony

struct Diag_NetworkBandView: View {
    @State private var bandInfo: [(String, String)] = []
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var radioHistory: [(Date, String)] = []

    var body: some View {
        Form {
            Section("Network Band Scanner") {
                VStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.up.forward")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Radio Band Monitor")
                        .font(.headline)
                    Text("Monitor active radio access technology and network bands")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Current Band") {
                ForEach(bandInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption) }
                }
            }

            if !radioHistory.isEmpty {
                Section("Band History") {
                    ForEach(radioHistory.suffix(10), id: \.0) { entry in
                        HStack {
                            Text(entry.0, style: .time).font(.caption.monospacedDigit())
                            Spacer()
                            Text(entry.1).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Radio Technologies") {
                VStack(alignment: .leading, spacing: 6) {
                    BandRow(gen: "5G NR", bands: "n1, n2, n5, n7, n12, n25, n28, n30, n38, n41, n48, n66, n71, n77, n78, n79, n258, n260, n261", speed: "Up to 10 Gbps")
                    BandRow(gen: "4G LTE", bands: "B1-B14, B17-B21, B25-B32, B34, B38-B43, B46, B48, B66, B71", speed: "Up to 1 Gbps")
                    BandRow(gen: "3G", bands: "UMTS 850/900/1700/1900/2100", speed: "Up to 42 Mbps")
                    BandRow(gen: "2G", bands: "GSM 850/900/1800/1900", speed: "Up to 384 Kbps")
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    isMonitoring ? stopMonitoring() : startMonitoring()
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Network Band")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshBand() }
        .onDisappear { stopMonitoring() }
    }

    private func refreshBand() {
        let info = CTTelephonyNetworkInfo()
        var details: [(String, String)] = []

        if let radios = info.serviceCurrentRadioAccessTechnology {
            for (slot, tech) in radios {
                let friendly = friendlyName(tech)
                details.append(("Radio (\(slot))", friendly))
                details.append(("Generation", generation(tech)))
                details.append(("Max Speed", maxSpeed(tech)))
            }
        }

        if let providers = info.serviceSubscriberCellularProviders {
            for (slot, carrier) in providers {
                details.append(("Carrier (\(slot))", carrier.carrierName ?? "Unknown"))
            }
        }

        bandInfo = details
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            refreshBand()
            let info = CTTelephonyNetworkInfo()
            if let radios = info.serviceCurrentRadioAccessTechnology {
                let summary = radios.values.map { friendlyName($0) }.joined(separator: ", ")
                radioHistory.append((Date(), summary))
                if radioHistory.count > 50 { radioHistory.removeFirst() }
            }
        }
    }

    private func stopMonitoring() { timer?.invalidate(); timer = nil; isMonitoring = false }

    private func friendlyName(_ tech: String) -> String {
        if tech.contains("NRNonStandalone") { return "5G NR NSA" }
        if tech.contains("NR") { return "5G NR" }
        if tech.contains("LTE") { return "LTE" }
        if tech.contains("eHRPD") { return "eHRPD" }
        if tech.contains("HSDPA") { return "HSDPA" }
        if tech.contains("HSUPA") { return "HSUPA" }
        if tech.contains("WCDMA") { return "WCDMA" }
        if tech.contains("EDGE") { return "EDGE" }
        if tech.contains("GPRS") { return "GPRS" }
        if tech.contains("CDMA") { return "CDMA" }
        return tech
    }

    private func generation(_ tech: String) -> String {
        if tech.contains("NR") { return "5G" }
        if tech.contains("LTE") { return "4G" }
        if tech.contains("WCDMA") || tech.contains("HSDPA") || tech.contains("HSUPA") { return "3G" }
        return "2G"
    }

    private func maxSpeed(_ tech: String) -> String {
        if tech.contains("NR") { return "Up to 10 Gbps" }
        if tech.contains("LTE") { return "Up to 1 Gbps" }
        if tech.contains("HSDPA") { return "Up to 42 Mbps" }
        if tech.contains("WCDMA") { return "Up to 14.4 Mbps" }
        return "Up to 384 Kbps"
    }
}

private struct BandRow: View {
    let gen: String
    let bands: String
    let speed: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(gen).font(.caption.weight(.medium))
            Text(bands).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            Text(speed).font(.caption2).foregroundStyle(.blue)
        }
    }
}
