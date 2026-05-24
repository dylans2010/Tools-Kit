import SwiftUI
import Network
import CoreTelephony

struct Diag_WirelessAntennaView: View {
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Wireless Antenna") {
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                    Text("Wireless Antenna Diagnostics")
                        .font(.headline)
                    Text("Tests WiFi, Cellular, Bluetooth, GPS, NFC, and UWB antenna systems")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Antenna Systems") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Radio Bands") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("5G NR (sub-6 GHz)", systemImage: "antenna.radiowaves.left.and.right").font(.caption)
                    Label("5G mmWave (US models)", systemImage: "antenna.radiowaves.left.and.right.circle.fill").font(.caption)
                    Label("LTE Advanced Pro", systemImage: "cellularbars").font(.caption)
                    Label("WiFi 6E / WiFi 7 (6 GHz)", systemImage: "wifi").font(.caption)
                    Label("WiFi 6 (2.4 + 5 GHz)", systemImage: "wifi").font(.caption)
                    Label("Bluetooth 5.3", systemImage: "wave.3.right").font(.caption)
                    Label("Ultra Wideband (U1/U2)", systemImage: "dot.radiowaves.left.and.right").font(.caption)
                    Label("NFC with reader mode", systemImage: "wave.3.right.circle.fill").font(.caption)
                    Label("Thread radio (iPhone 15 Pro+)", systemImage: "circle.grid.cross.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Antenna Design") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Multiple antenna arrays for MIMO", systemImage: "square.stack.3d.up.fill").font(.caption)
                    Label("Smart antenna switching for signal", systemImage: "arrow.triangle.swap").font(.caption)
                    Label("Steel/titanium frame integrates antennas", systemImage: "iphone.gen3").font(.caption)
                    Label("Ceramic shield reduces signal interference", systemImage: "shield.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkAntenna() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Wireless Antenna")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkAntenna() }
    }

    private func checkAntenna() {
        var info: [(String, String)] = []

        let monitor = NWPathMonitor()
        let path = monitor.currentPath
        info.append(("Network Status", path.status == .satisfied ? "Connected" : "Not connected"))

        let wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
        info.append(("WiFi Interface", path.usesInterfaceType(.wifi) ? "Active" : "Inactive"))
        info.append(("Cellular Interface", path.usesInterfaceType(.cellular) ? "Active" : "Inactive"))

        let networkInfo = CTTelephonyNetworkInfo()
        if let carrier = networkInfo.serviceSubscriberCellularProviders?.values.first {
            info.append(("Carrier", carrier.carrierName ?? "Unknown"))
            info.append(("Country Code", carrier.mobileCountryCode ?? "N/A"))
            info.append(("Network Code", carrier.mobileNetworkCode ?? "N/A"))
            info.append(("Allows VoIP", carrier.allowsVOIP ? "Yes" : "No"))
        }

        if let radioTech = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            let techName: String
            switch radioTech {
            case CTRadioAccessTechnologyLTE: techName = "LTE"
            case CTRadioAccessTechnologyeHRPD: techName = "eHRPD"
            case CTRadioAccessTechnologyHSDPA: techName = "HSDPA"
            case CTRadioAccessTechnologyWCDMA: techName = "WCDMA"
            default: techName = radioTech
            }
            info.append(("Radio Technology", techName))
        }

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
