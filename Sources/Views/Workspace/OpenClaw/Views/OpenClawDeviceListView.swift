import SwiftUI

struct OpenClawDeviceListView: View {
    private var registry = OpenClawDeviceRegistry.shared

    var body: some View {
        List {
            ForEach(registry.devices) { device in
                NavigationLink {
                    OpenClawDeviceDetailView(device: device)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(device.name).font(.headline)
                            Text(device.host).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if registry.activeDeviceID == device.id {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                        }
                    }
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    registry.remove(registry.devices[index].id)
                }
            }
        }
        .navigationTitle("Devices")
    }
}
