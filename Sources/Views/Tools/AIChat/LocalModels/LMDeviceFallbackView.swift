import SwiftUI

struct LMDeviceFallbackView: View {
    @StateObject private var discoveryService = LMLocalDevicesService.shared
    @StateObject private var connectionManager = LMConnectionManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Button(action: {
                    Task {
                        await discoveryService.performFullScan()
                    }
                }) {
                    HStack {
                        if discoveryService.isScanning {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Label(discoveryService.isScanning ? "Scanning LAN..." : "Refresh Devices", systemImage: "arrow.clockwise")
                            .font(.headline)
                    }
                }
                .disabled(discoveryService.isScanning)
            }

            if discoveryService.discoveredDevices.isEmpty && !discoveryService.isScanning {
                Section {
                    ContentUnavailableView("No Devices Found", systemImage: "wifi.exclamationmark", description: Text("Ensure LM Studio is running with the local server enabled on your network."))
                }
            } else {
                Section {
                    ForEach(discoveryService.discoveredDevices) { device in
                        DeviceSection(device: device)
                    }
                } header: {
                    Text("Discovered Nodes")
                }
            }
        }
        .navigationTitle("Device Discovery")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeviceSection: View {
    let device: LocalDevice
    @State private var isExpanded = false
    @StateObject private var connectionManager = LMConnectionManager.shared
    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @AppStorage("aichat_model_id") private var modelID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    connectionBadge

                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.ip)
                            .font(.headline)
                        Text("Port: \(device.port)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if device.isReachable {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.yellow)
                                Text(device.latency != nil ? "\(Int(device.latency! * 1000))ms" : "--")
                            }
                            .font(.caption2.bold())

                            Text("\(device.models.count) models")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        } else {
                            Text("Offline")
                                .font(.caption2.bold())
                                .foregroundColor(.red)
                        }
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)

            if isExpanded && device.isReachable {
                Divider()

                ForEach(device.models) { model in
                    Button(action: {
                        selectModel(model, from: device)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.name)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            if connectionManager.selectedDevice?.ipAddress == device.ip && connectionManager.selectedModel?.id == model.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(connectionManager.selectedDevice?.ipAddress == device.ip && connectionManager.selectedModel?.id == model.id ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var connectionBadge: some View {
        ZStack {
            Circle()
                .fill(badgeColor.opacity(0.1))
                .frame(width: 36, height: 36)
            Image(systemName: badgeIcon)
                .foregroundColor(badgeColor)
                .font(.system(size: 14, weight: .bold))
        }
    }

    private var badgeIcon: String {
        switch device.connectionType {
        case .lan: return "network"
        case .wifi: return "wifi"
        case .local: return "desktopcomputer"
        case .manualIP: return "m.circle.fill"
        }
    }

    private var badgeColor: Color {
        switch device.connectionType {
        case .lan: return .blue
        case .wifi: return .green
        case .local: return .purple
        case .manualIP: return .orange
        }
    }

    private func selectModel(_ model: LMStudioModel, from device: LocalDevice) {
        let lmDevice = LMDevice(
            id: device.id,
            name: "Discovered (\(device.ip))",
            ipAddress: device.ip,
            port: device.port,
            status: .online,
            lastSeen: Date(),
            models: device.models.map { LMModel(id: $0.id) }
        )

        connectionManager.selectedDevice = lmDevice
        connectionManager.selectedModel = LMModel(id: model.id)

        // Reflect globally
        selectedProviderID = "lmstudio"
        AIChatSettingsManager.shared.settings.selectedProviderID = "lmstudio"
        modelID = model.id
        AIChatSettingsManager.shared.settings.modelID = model.id

        // Reset manual config if any
        AIChatSettingsManager.shared.settings.selectedLocalConfigID = nil
    }
}
