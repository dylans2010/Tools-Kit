import SwiftUI
import CoreTelephony

struct Diag_APNConfigView: View {
    @State private var apnInfo: [(String, String)] = []
    @State private var carrierInfo: [(String, String)] = []

    var body: some View {
        Form {
            Section("APN Configuration") {
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Access Point Name Settings")
                        .font(.headline)
                    Text("View carrier APN and data connection settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Carrier & APN Details") {
                ForEach(carrierInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption) }
                }
            }

            Section("Network Configuration") {
                ForEach(apnInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption).foregroundStyle(.secondary) }
                }
            }

            Section("What is APN?") {
                Text("Access Point Name (APN) is the gateway between your carrier's cellular network and the internet. Incorrect APN settings can prevent data connectivity, MMS, and visual voicemail.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Troubleshooting") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Settings → Cellular → Cellular Data Options → Cellular Network", systemImage: "gearshape.fill").font(.caption)
                    Label("Reset APN: Settings → General → Transfer or Reset → Reset Network Settings", systemImage: "arrow.counterclockwise").font(.caption)
                    Label("Contact carrier for correct APN settings", systemImage: "phone.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section { Button { loadAPNInfo() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") } } }
        }
        .navigationTitle("APN Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadAPNInfo() }
    }

    private func loadAPNInfo() {
        let info = CTTelephonyNetworkInfo()
        var carrier: [(String, String)] = []
        var apn: [(String, String)] = []

        if let providers = info.serviceSubscriberCellularProviders {
            for (slot, prov) in providers {
                carrier.append(("Carrier (\(slot))", prov.carrierName ?? "Unknown"))
                carrier.append(("MCC (\(slot))", prov.mobileCountryCode ?? "N/A"))
                carrier.append(("MNC (\(slot))", prov.mobileNetworkCode ?? "N/A"))
                carrier.append(("Country (\(slot))", (prov.isoCountryCode ?? "N/A").uppercased()))
                carrier.append(("VoIP (\(slot))", prov.allowsVOIP ? "Yes" : "No"))
            }
        }

        if let radios = info.serviceCurrentRadioAccessTechnology {
            for (slot, tech) in radios {
                apn.append(("Radio Tech (\(slot))", tech))
            }
        }

        apn.append(("Data Service", info.dataServiceIdentifier ?? "Default"))
        apn.append(("Note", "iOS manages APN automatically for most carriers"))

        let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any]
        if let proxySettings = proxySettings {
            if let httpProxy = proxySettings["HTTPProxy"] as? String {
                apn.append(("HTTP Proxy", httpProxy))
            }
            if let httpPort = proxySettings["HTTPPort"] as? Int {
                apn.append(("HTTP Port", "\(httpPort)"))
            }
        }

        carrierInfo = carrier
        apnInfo = apn
    }
}
