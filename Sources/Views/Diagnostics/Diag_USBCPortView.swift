import SwiftUI

struct Diag_USBCPortView: View {
    @State private var hasUSBC = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("USB-C Port") {
                VStack(spacing: 12) {
                    Image(systemName: hasUSBC ? "cable.connector" : "cable.connector")
                        .font(.system(size: 52))
                        .foregroundStyle(hasUSBC ? .blue : .secondary)
                    Text(hasUSBC ? "USB-C Port" : "Lightning Port")
                        .font(.headline)
                    Text(hasUSBC ? "USB-C connector for charging, data, and accessories" : "Lightning connector detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Port Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("USB-C Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("USB 3 speeds up to 10 Gbps (Pro models)", systemImage: "bolt.fill").font(.caption)
                    Label("USB 2 speeds up to 480 Mbps (standard)", systemImage: "arrow.right").font(.caption)
                    Label("Video output via DisplayPort alt mode", systemImage: "tv.fill").font(.caption)
                    Label("Direct ProRes recording to external storage", systemImage: "externaldrive.fill").font(.caption)
                    Label("Charge accessories (reverse charging)", systemImage: "battery.100.bolt").font(.caption)
                    Label("USB Power Delivery fast charging", systemImage: "bolt.circle.fill").font(.caption)
                    Label("Connect USB audio interfaces", systemImage: "headphones").font(.caption)
                    Label("Connect MIDI keyboards", systemImage: "pianokeys").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("USB Speed Tiers") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("USB 2.0").font(.caption.weight(.medium))
                        Spacer()
                        Text("480 Mbps").font(.caption)
                    }
                    HStack {
                        Text("USB 3.0 (Gen 1)").font(.caption.weight(.medium))
                        Spacer()
                        Text("5 Gbps").font(.caption)
                    }
                    HStack {
                        Text("USB 3.1 (Gen 2)").font(.caption.weight(.medium))
                        Spacer()
                        Text("10 Gbps").font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 15 (all models) — USB 2.0", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 Pro / Pro Max — USB 3.0", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models) — USB 2.0", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 Pro / Pro Max — USB 3.0", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkPort() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("USB-C Port")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkPort() }
    }

    private func checkPort() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let usbcModels = [
            "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        let usb3Models = [
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2"
        ]
        hasUSBC = usbcModels.contains(modelId)
        let hasUSB3 = usb3Models.contains(modelId)

        info.append(("Connector", hasUSBC ? "USB-C" : "Lightning"))
        info.append(("USB Speed", hasUSB3 ? "USB 3 (10 Gbps)" : hasUSBC ? "USB 2 (480 Mbps)" : "Lightning"))
        info.append(("DisplayPort Output", hasUSBC ? "Supported" : "Via adapter"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
