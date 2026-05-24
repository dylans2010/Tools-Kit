import SwiftUI
import Network

struct Diag_WiFi6ECheckView: View {
    @State private var supported = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("WiFi 6E / WiFi 7") {
                VStack(spacing: 12) {
                    Image(systemName: supported ? "wifi.circle.fill" : "wifi.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(supported ? .green : .secondary)
                    Text(supported ? "WiFi 6E+ Supported" : "WiFi 6E Not Available")
                        .font(.headline)
                    Text("6 GHz WiFi band support for faster speeds and lower interference")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("WiFi Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("WiFi Standards") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("WiFi 4 (802.11n)").font(.caption.weight(.medium))
                        Spacer()
                        Text("Up to 600 Mbps").font(.caption)
                    }
                    HStack {
                        Text("WiFi 5 (802.11ac)").font(.caption.weight(.medium))
                        Spacer()
                        Text("Up to 3.5 Gbps").font(.caption)
                    }
                    HStack {
                        Text("WiFi 6 (802.11ax)").font(.caption.weight(.medium))
                        Spacer()
                        Text("Up to 9.6 Gbps").font(.caption)
                    }
                    HStack {
                        Text("WiFi 6E (6 GHz)").font(.caption.weight(.medium))
                        Spacer()
                        Text("Up to 9.6 Gbps + 6 GHz").font(.caption)
                    }
                    HStack {
                        Text("WiFi 7 (802.11be)").font(.caption.weight(.medium))
                        Spacer()
                        Text("Up to 46 Gbps").font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Benefits of 6 GHz") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Less interference (new spectrum)", systemImage: "wifi").font(.caption)
                    Label("Wider channels (up to 160 MHz)", systemImage: "arrow.left.and.right").font(.caption)
                    Label("Lower latency", systemImage: "timer").font(.caption)
                    Label("Better for dense environments", systemImage: "building.2.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 15 Pro / Pro Max (WiFi 6E)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models) (WiFi 7)", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkWiFi() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("WiFi 6E / 7")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkWiFi() }
    }

    private func checkWiFi() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let wifi6eModels = ["iPhone16,1", "iPhone16,2"]
        let wifi7Models = [
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]

        if wifi7Models.contains(modelId) {
            supported = true
            info.append(("WiFi Standard", "WiFi 7 (802.11be)"))
        } else if wifi6eModels.contains(modelId) {
            supported = true
            info.append(("WiFi Standard", "WiFi 6E (6 GHz)"))
        } else {
            supported = false
            info.append(("WiFi Standard", "WiFi 6 or earlier"))
        }

        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        let path = monitor.currentPath
        info.append(("WiFi Active", path.status == .satisfied ? "Yes" : "No"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
