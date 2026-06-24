import SwiftUI

struct OpenClawDeviceDetailView: View {
    let device: OpenClawDevice
    @StateObject private var registry = OpenClawDeviceRegistry.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Information") {
                LabeledContent("ID", value: device.id)
                LabeledContent("Host", value: device.host)
                LabeledContent("Port", value: "\(device.port)")
                if let last = device.lastConnected {
                    LabeledContent("Last Connected", value: last.formatted())
                }
            }

            Section {
                Button("Set as Active") {
                    registry.activeDeviceID = device.id
                    registry.save()
                }
                .disabled(registry.activeDeviceID == device.id)

                Button("Remove Device", role: .destructive) {
                    registry.remove(device.id)
                    dismiss()
                }
            }
        }
        .navigationTitle(device.name)
    }
}
