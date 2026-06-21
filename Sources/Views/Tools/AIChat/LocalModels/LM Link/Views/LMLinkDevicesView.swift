import SwiftUI

struct LMLinkDevicesView: View {
    @StateObject private var discoveryService = LMDeviceDiscoveryService()
    @StateObject private var connectionManager = LMConnectionManager.shared

    var body: some View {
        List {
            Section(header: Text("Discovered Devices")) {
                if discoveryService.discoveredDevices.isEmpty {
                    Text("Searching for devices on local network...")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(discoveryService.discoveredDevices) { device in
                        NavigationLink(destination: LMLinkDeviceDetailView(device: device)) {
                            LMDeviceRowView(device: device)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            discoveryService.startDiscovery()
        }
        .onDisappear {
            discoveryService.stopDiscovery()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    discoveryService.stopDiscovery()
                    discoveryService.startDiscovery()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}
