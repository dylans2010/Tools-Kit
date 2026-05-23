import SwiftUI
import NearbyInteraction

struct Diag_UWBChipView: View {
    @State private var isSupported = false
    @State private var hasChecked = false
    @State private var chipDetails: [(String, String)] = []

    var body: some View {
        Form {
            Section("Ultra Wideband (UWB) Chip") {
                VStack(spacing: 12) {
                    Image(systemName: isSupported ? "dot.radiowaves.left.and.right" : "dot.radiowaves.right")
                        .font(.system(size: 52))
                        .foregroundStyle(isSupported ? .blue : .secondary)
                    Text(isSupported ? "UWB Chip Available" : "UWB Not Available")
                        .font(.headline)
                    Text(isSupported ? "U1/U2 chip detected — spatial awareness supported" : "This device does not have a UWB chip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Chip Details") {
                ForEach(chipDetails, id: \.0) { detail in
                    LabeledContent(detail.0) {
                        Text(detail.1)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("UWB Capabilities") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Precision Finding (AirTag, Find My)", systemImage: "location.magnifyingglass")
                        .font(.caption)
                    Label("Spatial awareness with other UWB devices", systemImage: "person.2.wave.2")
                        .font(.caption)
                    Label("Digital car key (UWB-based)", systemImage: "key.fill")
                        .font(.caption)
                    Label("Nearby Interaction framework", systemImage: "arrow.triangle.swap")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 11 and later (U1 chip)", systemImage: "iphone.gen2")
                        .font(.caption)
                    Label("iPhone 15 and later (U2 chip)", systemImage: "iphone.gen3")
                        .font(.caption)
                    Label("Apple Watch Series 6 and later", systemImage: "applewatch")
                        .font(.caption)
                    Label("AirTag", systemImage: "airtag")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    checkUWB()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-check")
                    }
                }
            }
        }
        .navigationTitle("UWB Chip")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkUWB() }
    }

    private func checkUWB() {
        var details: [(String, String)] = []

        let supported = NISession.isSupported
        isSupported = supported
        details.append(("NI Session Supported", supported ? "Yes" : "No"))

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        details.append(("Device Model", modelId))

        let uwbModels = [
            "iPhone12", "iPhone13", "iPhone14", "iPhone15", "iPhone16", "iPhone17"
        ]
        let hasUWBHardware = uwbModels.contains { modelId.hasPrefix($0) }
        details.append(("UWB Hardware", hasUWBHardware || supported ? "Present" : "Not detected"))

        if supported {
            let chipGen = modelId.hasPrefix("iPhone16") || modelId.hasPrefix("iPhone17") ? "U2" : "U1"
            details.append(("Chip Generation", chipGen))
        }

        details.append(("Nearby Interaction", supported ? "Available" : "Not available"))
        details.append(("Precision Finding", supported ? "Supported" : "Not supported"))

        chipDetails = details
        hasChecked = true
    }
}
