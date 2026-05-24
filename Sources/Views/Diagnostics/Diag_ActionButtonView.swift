import SwiftUI

struct Diag_ActionButtonView: View {
    @State private var hasActionButton = false
    @State private var deviceModel = ""
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Action Button") {
                VStack(spacing: 12) {
                    Image(systemName: hasActionButton ? "button.horizontal.top.press.fill" : "button.horizontal.top.press")
                        .font(.system(size: 52))
                        .foregroundStyle(hasActionButton ? .purple : .secondary)
                    Text(hasActionButton ? "Action Button Available" : "Action Button Not Available")
                        .font(.headline)
                    Text("Customizable hardware button replacing the mute switch on iPhone 15 Pro+")
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

            Section("Available Actions") {
                VStack(alignment: .leading, spacing: 6) {
                    actionRow("Silent Mode", icon: "bell.slash.fill", desc: "Toggle ring/silent")
                    actionRow("Focus", icon: "moon.fill", desc: "Toggle Do Not Disturb or Focus")
                    actionRow("Camera", icon: "camera.fill", desc: "Open Camera app")
                    actionRow("Flashlight", icon: "flashlight.on.fill", desc: "Toggle flashlight")
                    actionRow("Voice Memo", icon: "mic.fill", desc: "Start recording")
                    actionRow("Magnifier", icon: "plus.magnifyingglass", desc: "Open Magnifier")
                    actionRow("Shortcut", icon: "command.circle.fill", desc: "Run any Shortcut")
                    actionRow("Accessibility", icon: "accessibility", desc: "Custom accessibility action")
                    actionRow("Translate", icon: "character.book.closed.fill", desc: "Open Translate")
                    actionRow("Controls", icon: "slider.horizontal.3", desc: "Quick control toggle (iOS 18+)")
                }
                .padding(.vertical, 4)
            }

            Section("How It Works") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Long press to activate the assigned action", systemImage: "hand.point.up.left.fill").font(.caption)
                    Label("Capacitive touch surface detects press", systemImage: "hand.tap.fill").font(.caption)
                    Label("Configure in Settings > Action Button", systemImage: "gear").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 15 Pro", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models)", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkActionButton() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Action Button")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkActionButton() }
    }

    @ViewBuilder
    private func actionRow(_ name: String, icon: String, desc: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.purple)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.caption.weight(.medium))
                Text(desc).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private func checkActionButton() {
        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        deviceModel = modelId

        let actionButtonModels = [
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        hasActionButton = actionButtonModels.contains(modelId)

        var info: [(String, String)] = []
        info.append(("Model Identifier", modelId))
        info.append(("Action Button", hasActionButton ? "Present" : "Not present"))
        info.append(("iOS Version", UIDevice.current.systemVersion))
        info.append(("Device Name", UIDevice.current.name))
        details = info
    }
}
