import SwiftUI
import CoreTelephony
import Network

struct Diag_RoamingStatusView: View {
    @State private var roamingInfo: [(String, String)] = []
    @State private var isRoaming = false

    var body: some View {
        Form {
            Section("Roaming Status") {
                VStack(spacing: 12) {
                    Image(systemName: isRoaming ? "globe.americas.fill" : "house.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(isRoaming ? .orange : .green)
                    Text(isRoaming ? "Roaming Detected" : "Home Network")
                        .font(.headline)
                    Text(isRoaming ? "Device may be using a foreign carrier network" : "Connected to home carrier network")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Network Details") {
                ForEach(roamingInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption) }
                }
            }

            Section("Roaming Tips") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Disable data roaming: Settings → Cellular → Data Roaming", systemImage: "antenna.radiowaves.left.and.right.slash").font(.caption)
                    Label("Use WiFi when abroad to avoid charges", systemImage: "wifi").font(.caption)
                    Label("Consider a local eSIM for international travel", systemImage: "esim.fill").font(.caption)
                    Label("Enable WiFi Calling if supported", systemImage: "phone.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section { Button { checkRoaming() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") } } }
        }
        .navigationTitle("Roaming Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkRoaming() }
    }

    private func checkRoaming() {
        let info = CTTelephonyNetworkInfo()
        var details: [(String, String)] = []
        var roamingDetected = false

        if let providers = info.serviceSubscriberCellularProviders {
            let deviceLocale = Locale.current.region?.identifier ?? ""
            for (slot, carrier) in providers {
                let carrierCountry = carrier.isoCountryCode?.uppercased() ?? ""
                let possibleRoaming = !carrierCountry.isEmpty && !deviceLocale.isEmpty && carrierCountry != deviceLocale.uppercased()
                if possibleRoaming { roamingDetected = true }

                details.append(("Carrier (\(slot))", carrier.carrierName ?? "Unknown"))
                details.append(("Carrier Country (\(slot))", carrierCountry))
                details.append(("Device Region", deviceLocale))
                if possibleRoaming {
                    details.append(("Roaming (\(slot))", "Possible — carrier country differs from device region"))
                }
            }
        }

        if let radios = info.serviceCurrentRadioAccessTechnology {
            for (slot, tech) in radios {
                details.append(("Radio (\(slot))", tech))
            }
        }

        let monitor = NWPathMonitor(requiredInterfaceType: .cellular)
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                details.append(("Cellular Connected", path.status == .satisfied ? "Yes" : "No"))
                details.append(("Expensive Connection", path.isExpensive ? "Yes (typical for roaming)" : "No"))
                monitor.cancel()
                roamingInfo = details
            }
        }
        monitor.start(queue: .global(qos: .utility))
        isRoaming = roamingDetected
    }
}
