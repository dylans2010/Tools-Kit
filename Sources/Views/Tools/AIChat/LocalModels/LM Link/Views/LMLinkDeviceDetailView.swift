import SwiftUI

struct LMLinkDeviceDetailView: View {
    let device: LMDevice
    @StateObject private var connectionManager = LMConnectionManager.shared

    var body: some View {
        List {
            Section(header: Text("Device Info")) {
                LMLinkLabeledContent("Name", value: device.name)
                LMLinkLabeledContent("IP Address", value: device.ipAddress)
                LMLinkLabeledContent("Port", value: "\(device.port)")
                LMLinkLabeledContent("Status", value: device.status.rawValue.capitalized)
                    .foregroundColor(device.status == .online ? .green : .red)
            }

            Section(header: Text("Models")) {
                if device.models.isEmpty {
                    Text("No models discovered on this device.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(device.models) { model in
                        NavigationLink(destination: LMLinkModelDetailView(device: device, model: model)) {
                            LMModelRowView(model: model)
                        }
                    }
                }
            }

            Section {
                Button(action: {
                    connectionManager.selectDevice(device)
                }) {
                    HStack {
                        Spacer()
                        Text(connectionManager.selectedDevice?.id == device.id ? "Selected" : "Select Device")
                        Spacer()
                    }
                }
                .disabled(connectionManager.selectedDevice?.id == device.id)
            }
        }
        .navigationTitle(device.name)
    }
}

struct LMLinkLabeledContent: View {
    let label: String
    let value: String

    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
