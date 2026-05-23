import SwiftUI
import CoreTelephony

struct Diag_eSIMStatusView: View {
    @State private var details: [(String, String)] = []
    @State private var eSIMSupported = false

    var body: some View {
        Form {
            Section("eSIM Status") {
                VStack(spacing: 12) {
                    Image(systemName: "esim.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(eSIMSupported ? .blue : .secondary)
                    Text(eSIMSupported ? "eSIM Supported" : "Checking eSIM Support...")
                        .font(.headline)
                    Text(eSIMSupported ? "Device supports embedded SIM functionality" : "eSIM may not be available on this device")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("eSIM Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) {
                        Text(d.1).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section("eSIM Compatibility") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone XS/XR and later support eSIM", systemImage: "iphone.gen2")
                        .font(.caption)
                    Label("iPhone 14+ (US) are eSIM-only", systemImage: "iphone.gen3")
                        .font(.caption)
                    Label("iPad Pro/Air (select models) support eSIM", systemImage: "ipad")
                        .font(.caption)
                    Label("Apple Watch (GPS+Cellular) supports eSIM", systemImage: "applewatch")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("How to Add eSIM") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Settings → Cellular → Add eSIM", systemImage: "gearshape.fill")
                        .font(.caption)
                    Label("Scan QR code from carrier", systemImage: "qrcode.viewfinder")
                        .font(.caption)
                    Label("Transfer from another device", systemImage: "arrow.triangle.swap")
                        .font(.caption)
                    Label("Use carrier app", systemImage: "app.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkESIM() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") }
                }
            }
        }
        .navigationTitle("eSIM Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkESIM() }
    }

    private func checkESIM() {
        var info: [(String, String)] = []
        let netInfo = CTTelephonyNetworkInfo()

        if let providers = netInfo.serviceSubscriberCellularProviders {
            let slotCount = providers.count
            info.append(("Active SIM Slots", "\(slotCount)"))
            info.append(("Dual SIM Active", slotCount > 1 ? "Yes" : "No"))

            for (slot, carrier) in providers {
                info.append(("Slot \(slot)", carrier.carrierName ?? "No carrier"))
            }

            eSIMSupported = true
        } else {
            info.append(("SIM Slots", "Cannot detect"))
            eSIMSupported = false
        }

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let eSIMModels = ["iPhone11", "iPhone12", "iPhone13", "iPhone14", "iPhone15", "iPhone16", "iPhone17"]
        let modelSupports = eSIMModels.contains { modelId.hasPrefix($0) }
        eSIMSupported = modelSupports
        info.append(("Hardware eSIM", modelSupports ? "Supported" : "Check Settings → Cellular"))

        let usOnlyESIM = modelId.hasPrefix("iPhone15") || modelId.hasPrefix("iPhone16") || modelId.hasPrefix("iPhone17")
        if usOnlyESIM {
            info.append(("SIM Tray", "eSIM-only (US model, no physical tray)"))
        }

        details = info
    }
}
