import SwiftUI

struct LMLinkMainView: View {
    @ObservedObject private var authManager = LMLinkAuthManager.shared
    @ObservedObject private var discoveryService = LMDeviceDiscoveryService.shared

    var body: some View {
        List {
            Section {
                NavigationLink(destination: LMLinkDashboardView()) {
                    Label("Dashboard", systemImage: "house.fill")
                }
                NavigationLink(destination: LMLinkDevicesView()) {
                    Label("Devices", systemImage: "desktopcomputer")
                }
                .disabled(!authManager.isLinked)

                NavigationLink(destination: LMLinkModelsView()) {
                    Label("Models", systemImage: "cpu")
                }
                .disabled(!authManager.isLinked)
            } header: {
                Text("Main")
            }

            Section {
                NavigationLink(destination: LMLinkAccountView()) {
                    Label("Account", systemImage: "person.crop.circle")
                }
                NavigationLink(destination: LMLinkSettingsView()) {
                    Label("Settings", systemImage: "gearshape")
                }
            } header: {
                Text("Preferences")
            }
        }
        .navigationTitle("LM Link")
        .overlay {
            if discoveryService.isScanning && discoveryService.discoveredDevices.isEmpty {
                VStack {
                    ProgressView()
                    Text("Initializing LM Link...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).opacity(0.8))
            }
        }
    }
}
