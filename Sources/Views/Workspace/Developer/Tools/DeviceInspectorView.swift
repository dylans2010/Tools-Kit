import SwiftUI

struct DeviceInspectorView: View {
    var body: some View {
        List {
            Section("Device Information") {
                infoRow(label: "Model", value: UIDevice.current.model)
                infoRow(label: "System Name", value: UIDevice.current.systemName)
                infoRow(label: "System Version", value: UIDevice.current.systemVersion)
                infoRow(label: "Device Name", value: UIDevice.current.name)
            }

            Section("Screen Details") {
                infoRow(label: "Width", value: "\(Int(UIScreen.main.bounds.width)) pt")
                infoRow(label: "Height", value: "\(Int(UIScreen.main.bounds.height)) pt")
                infoRow(label: "Scale", value: "\(Int(UIScreen.main.scale))x")
            }

            Section("Locale & Region") {
                infoRow(label: "Language", value: Locale.current.language.languageCode?.identifier ?? "Unknown")
                infoRow(label: "Region", value: Locale.current.language.region?.identifier ?? "Unknown")
                infoRow(label: "Calendar", value: Calendar.current.identifier == .gregorian ? "Gregorian" : "Other")
            }

            Section("Capabilities") {
                capabilityRow(label: "Multitasking Supported", value: UIDevice.current.isMultitaskingSupported)
                capabilityRow(label: "Proximity Monitoring", value: UIDevice.current.isProximityMonitoringEnabled)
            }
        }
        .navigationTitle("Device Inspector")
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary).font(.subheadline)
        }
    }

    private func capabilityRow(label: String, value: Bool) -> some View {
        HStack {
            Text(label)
            Spacer()
            Image(systemName: value ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(value ? .green : .red)
        }
    }
}
