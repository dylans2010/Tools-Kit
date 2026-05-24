import SwiftUI

struct Diag_AlwaysOnDisplayView: View {
    @State private var supported = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Always On Display") {
                VStack(spacing: 12) {
                    Image(systemName: supported ? "display" : "display")
                        .font(.system(size: 52))
                        .foregroundStyle(supported ? .blue : .secondary)
                    Text(supported ? "Always On Display Available" : "Always On Display Not Available")
                        .font(.headline)
                    Text("LTPO OLED display that dims to 1Hz showing time, widgets, and wallpaper")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Display Info") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Always On Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Dimmed lock screen always visible", systemImage: "lock.fill").font(.caption)
                    Label("Time and date always shown", systemImage: "clock.fill").font(.caption)
                    Label("Widgets remain visible", systemImage: "square.grid.2x2.fill").font(.caption)
                    Label("Wallpaper dims intelligently", systemImage: "photo.fill").font(.caption)
                    Label("Live Activities visible", systemImage: "clock.badge.fill").font(.caption)
                    Label("Notification badges shown", systemImage: "bell.badge.fill").font(.caption)
                    Label("1Hz minimum refresh rate (LTPO)", systemImage: "arrow.clockwise").font(.caption)
                    Label("Turns off face-down or in pocket", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Display Technology") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("LTPO OLED — Variable refresh 1-120Hz", systemImage: "display").font(.caption)
                    Label("ProMotion adaptive refresh rate", systemImage: "gauge.with.dots.needle.67percent").font(.caption)
                    Label("Peak brightness up to 2000 nits", systemImage: "sun.max.fill").font(.caption)
                    Label("Individual pixel control for power savings", systemImage: "square.grid.4x3.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 14 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkAOD() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Always On Display")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkAOD() }
    }

    private func checkAOD() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let aodModels = [
            "iPhone15,2", "iPhone15,3",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2"
        ]
        supported = aodModels.contains(modelId)
        info.append(("Always On Display", supported ? "Supported" : "Not Supported"))

        let screenBounds = UIScreen.main.bounds
        info.append(("Screen Size", "\(Int(screenBounds.width)) x \(Int(screenBounds.height))"))
        info.append(("Scale", "\(Int(UIScreen.main.scale))x"))
        info.append(("Max FPS", "\(Int(UIScreen.main.maximumFramesPerSecond))"))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
