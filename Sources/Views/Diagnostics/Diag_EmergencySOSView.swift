import SwiftUI

struct Diag_EmergencySOSView: View {
    @State private var supported = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Emergency SOS via Satellite") {
                VStack(spacing: 12) {
                    Image(systemName: supported ? "sos.circle.fill" : "sos.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(supported ? .orange : .secondary)
                    Text(supported ? "Satellite SOS Available" : "Satellite SOS Not Available")
                        .font(.headline)
                    Text("Contact emergency services via satellite when no cellular or WiFi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Device Info") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Satellite Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Emergency SOS text to emergency services", systemImage: "sos.circle.fill").font(.caption)
                    Label("Find My via satellite", systemImage: "location.fill").font(.caption)
                    Label("Roadside Assistance via satellite", systemImage: "car.fill").font(.caption)
                    Label("Messages via satellite (iPhone 16+)", systemImage: "message.fill").font(.caption)
                    Label("On-screen satellite pointing guide", systemImage: "antenna.radiowaves.left.and.right").font(.caption)
                    Label("Medical ID sharing with responders", systemImage: "heart.text.square.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("How It Works") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Point iPhone at sky following on-screen guide", systemImage: "iphone.gen3").font(.caption)
                    Label("Compressed text messages via Globalstar satellites", systemImage: "satellite.fill").font(.caption)
                    Label("Works outdoors with clear view of sky", systemImage: "cloud.sun.fill").font(.caption)
                    Label("Messages relayed to local emergency centers", systemImage: "building.2.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 14 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models)", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkSatellite() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Emergency SOS Satellite")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkSatellite() }
    }

    private func checkSatellite() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let satelliteModels = [
            "iPhone14,7", "iPhone14,8", "iPhone15,2", "iPhone15,3",
            "iPhone15,4", "iPhone15,5",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        supported = satelliteModels.contains(modelId)
        info.append(("Satellite Connectivity", supported ? "Supported" : "Not Supported"))
        info.append(("iOS Version", UIDevice.current.systemVersion))
        info.append(("Device Name", UIDevice.current.name))

        details = info
    }
}
