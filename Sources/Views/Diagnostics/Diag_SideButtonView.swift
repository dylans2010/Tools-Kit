import SwiftUI

struct Diag_SideButtonView: View {
    @State private var details: [(String, String)] = []
    @State private var lockPressCount = 0
    @State private var screenshotDetected = false

    var body: some View {
        Form {
            Section("Side / Power Button") {
                VStack(spacing: 12) {
                    Image(systemName: "power.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                    Text("Side Button Test")
                        .font(.headline)
                    Text("Tests the side (power/lock) button functionality")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Button Info") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Test Instructions") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text("1.").font(.caption.weight(.bold))
                        Text("Press the side button briefly to lock/wake the screen — the app will detect the state change")
                            .font(.caption)
                    }
                    HStack(alignment: .top) {
                        Text("2.").font(.caption.weight(.bold))
                        Text("Press Side + Volume Up to take a screenshot — the app will detect it")
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Detection Results") {
                LabeledContent("Screenshot Detected") {
                    HStack {
                        Image(systemName: screenshotDetected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(screenshotDetected ? .green : .secondary)
                        Text(screenshotDetected ? "Yes" : "Not yet")
                            .font(.caption)
                    }
                }
            }

            Section("Side Button Functions") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Single press — Lock/Wake screen", systemImage: "lock.fill").font(.caption)
                    Label("Double press — Apple Pay", systemImage: "creditcard.fill").font(.caption)
                    Label("Triple press — Accessibility shortcut", systemImage: "accessibility").font(.caption)
                    Label("Long press — Siri", systemImage: "mic.fill").font(.caption)
                    Label("Side + Volume Up — Screenshot", systemImage: "camera.viewfinder").font(.caption)
                    Label("Side + Volume Up hold — Emergency SOS", systemImage: "sos.circle.fill").font(.caption)
                    Label("Side + Volume Down — Force restart", systemImage: "arrow.clockwise").font(.caption)
                    Label("5x press — Emergency SOS (some regions)", systemImage: "exclamationmark.triangle.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    screenshotDetected = false
                    lockPressCount = 0
                } label: {
                    HStack { Image(systemName: "arrow.counterclockwise"); Text("Reset") }
                }
            }
        }
        .navigationTitle("Side Button")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkButton() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            screenshotDetected = true
        }
    }

    private func checkButton() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))
        info.append(("Button Type", "Side Button"))
        info.append(("iOS Version", UIDevice.current.systemVersion))
        details = info
    }
}
