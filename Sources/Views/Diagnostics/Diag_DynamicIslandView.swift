import SwiftUI

struct Diag_DynamicIslandView: View {
    @State private var hasDynamicIsland = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Dynamic Island") {
                VStack(spacing: 12) {
                    Image(systemName: hasDynamicIsland ? "pill.circle.fill" : "pill.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(hasDynamicIsland ? .purple : .secondary)
                    Text(hasDynamicIsland ? "Dynamic Island Available" : "Dynamic Island Not Available")
                        .font(.headline)
                    Text("Interactive pill-shaped display cutout for live activities and alerts")
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

            Section("Dynamic Island Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Live Activities display", systemImage: "clock.badge.fill").font(.caption)
                    Label("Music now playing controls", systemImage: "music.note").font(.caption)
                    Label("Timer and stopwatch", systemImage: "timer").font(.caption)
                    Label("Navigation directions", systemImage: "location.fill").font(.caption)
                    Label("Phone call status", systemImage: "phone.fill").font(.caption)
                    Label("AirDrop progress", systemImage: "square.and.arrow.down.fill").font(.caption)
                    Label("AirPods connection", systemImage: "airpodspro").font(.caption)
                    Label("Food delivery tracking", systemImage: "bag.fill").font(.caption)
                    Label("Sports scores live", systemImage: "sportscourt.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 14 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models)", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkDynamicIsland() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Dynamic Island")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkDynamicIsland() }
    }

    private func checkDynamicIsland() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let dynamicIslandModels = [
            "iPhone15,2", "iPhone15,3",
            "iPhone15,4", "iPhone15,5",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        hasDynamicIsland = dynamicIslandModels.contains(modelId)
        info.append(("Dynamic Island", hasDynamicIsland ? "Present" : "Not present"))

        let screenBounds = UIScreen.main.bounds
        info.append(("Screen Size", "\(Int(screenBounds.width)) x \(Int(screenBounds.height))"))
        info.append(("Scale", "\(Int(UIScreen.main.scale))x"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
