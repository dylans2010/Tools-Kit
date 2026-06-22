import SwiftUI

struct LMLinkDevicesView: View {
    @ObservedObject private var discoveryService = LMDeviceDiscoveryService.shared
    @StateObject private var connectionManager = LMConnectionManager.shared
    @StateObject private var authManager = LMLinkAuthManager.shared

    var body: some View {
        Group {
            if !authManager.$isConnected.wrappedValue {
                VStack(spacing: 20) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("LM Link Required")
                        .font(.title2)
                        .bold()

                    Text("You must link your LM Studio account before you can discover and manage devices.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Button(action: {
                        authManager.initiateLink()
                    }) {
                        Text("Link LM Studio Account")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        if discoveryService.isScanning && discoveryService.discoveredDevices.isEmpty {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Searching for devices...")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        } else if discoveryService.discoveredDevices.isEmpty {
                            Text("No devices found. Ensure LM Studio is running with LM Link enabled.")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(discoveryService.discoveredDevices.filter { $0.status == .online }) { device in
                                NavigationLink(destination: LMLinkDeviceDetailView(device: device)) {
                                    LMDeviceRowView(device: device)
                                }
                            }
                        }
                    } header: {
                        Text("Discovered Devices")
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    await discoveryService.performFullScan()
                }
            }
        }
        .navigationTitle("Devices")
        .onAppear {
            Task {
                await discoveryService.performFullScan()
            }
        }
    }
}
