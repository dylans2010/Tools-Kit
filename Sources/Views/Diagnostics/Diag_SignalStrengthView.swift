import SwiftUI
import CoreTelephony
import Network

struct Diag_SignalStrengthView: View {
    @State private var signalInfo: [(String, String)] = []
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var history: [(Date, String)] = []

    var body: some View {
        Form {
            Section("Signal Strength Monitor") {
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 44))
                        .foregroundStyle(.green)
                    Text("Cellular Signal Monitor")
                        .font(.headline)
                    Text("Real-time carrier signal and radio technology monitoring")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Current Signal") {
                ForEach(signalInfo, id: \.0) { info in
                    LabeledContent(info.0) {
                        Text(info.1)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !history.isEmpty {
                Section("Signal Log") {
                    ForEach(history.suffix(10), id: \.0) { entry in
                        HStack {
                            Text(entry.0, style: .time).font(.caption.monospacedDigit())
                            Spacer()
                            Text(entry.1).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
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
        .navigationTitle("Signal Strength")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshSignal() }
        .onDisappear { stopMonitoring() }
    }

    private func refreshSignal() {
        let info = CTTelephonyNetworkInfo()
        var details: [(String, String)] = []

        if let radios = info.serviceCurrentRadioAccessTechnology {
            for (slot, tech) in radios {
                details.append(("Radio (\(slot))", friendlyRadio(tech)))
                details.append(("Generation", radioGeneration(tech)))
            }
        }

        if let providers = info.serviceSubscriberCellularProviders {
            for (slot, carrier) in providers {
                if let name = carrier.carrierName {
                    details.append(("Carrier (\(slot))", name))
                }
            }
        }

        details.append(("Data Service", info.dataServiceIdentifier ?? "Default"))

        let monitor = NWPathMonitor(requiredInterfaceType: .cellular)
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                details.append(("Cellular Status", path.status == .satisfied ? "Connected" : "Not Connected"))
                details.append(("Expensive", path.isExpensive ? "Yes" : "No"))
                monitor.cancel()
                signalInfo = details
            }
        }
        monitor.start(queue: .global(qos: .utility))
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let info = CTTelephonyNetworkInfo()
            var status = "Unknown"
            if let radios = info.serviceCurrentRadioAccessTechnology {
                status = radios.values.map { friendlyRadio($0) }.joined(separator: ", ")
            }
            history.append((Date(), status))
            if history.count > 50 { history.removeFirst() }
            refreshSignal()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func friendlyRadio(_ tech: String) -> String {
        if tech.contains("NR") { return "5G NR" }
        if tech.contains("LTE") { return "4G LTE" }
        if tech.contains("WCDMA") { return "3G" }
        if tech.contains("EDGE") { return "2G EDGE" }
        return tech
    }

    private func radioGeneration(_ tech: String) -> String {
        if tech.contains("NR") { return "5G" }
        if tech.contains("LTE") { return "4G" }
        if tech.contains("WCDMA") || tech.contains("HSDPA") { return "3G" }
        return "2G"
    }
}
