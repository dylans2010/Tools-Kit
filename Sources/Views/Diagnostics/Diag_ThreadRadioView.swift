import SwiftUI

struct Diag_ThreadRadioView: View {
    @State private var supported = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Thread Radio") {
                VStack(spacing: 12) {
                    Image(systemName: supported ? "circle.grid.cross.fill" : "circle.grid.cross")
                        .font(.system(size: 52))
                        .foregroundStyle(supported ? .green : .secondary)
                    Text(supported ? "Thread Radio Available" : "Thread Radio Not Available")
                        .font(.headline)
                    Text("Low-power mesh networking protocol for smart home devices (Matter/Thread)")
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

            Section("Thread Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Matter smart home protocol support", systemImage: "homekit").font(.caption)
                    Label("Thread Border Router capability", systemImage: "network").font(.caption)
                    Label("Low-power 802.15.4 mesh networking", systemImage: "circle.grid.cross.fill").font(.caption)
                    Label("Direct communication with Thread devices", systemImage: "dot.radiowaves.left.and.right").font(.caption)
                    Label("Self-healing mesh network", systemImage: "arrow.triangle.2.circlepath").font(.caption)
                    Label("IPv6-based protocol", systemImage: "globe").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Smart Home Uses") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Smart lights and switches", systemImage: "lightbulb.fill").font(.caption)
                    Label("Door locks and sensors", systemImage: "lock.fill").font(.caption)
                    Label("Temperature and humidity sensors", systemImage: "thermometer.medium").font(.caption)
                    Label("Motion detectors", systemImage: "figure.walk").font(.caption)
                    Label("Smart plugs and outlets", systemImage: "powerplug.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 15 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("HomePod mini, Apple TV 4K", systemImage: "homepodmini.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkThread() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Thread Radio")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkThread() }
    }

    private func checkThread() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let threadModels = [
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        supported = threadModels.contains(modelId)
        info.append(("Thread Radio", supported ? "Present" : "Not present"))
        info.append(("Matter Support", "iOS 16.1+"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
