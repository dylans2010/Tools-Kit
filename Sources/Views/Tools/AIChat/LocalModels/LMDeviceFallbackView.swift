import SwiftUI

struct LMDeviceFallbackView: View {
    @StateObject private var discoveryService = LMLocalDevicesService.shared
    @StateObject private var connectionManager = LMConnectionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod: DiscoveryMethod = .lan
    @State private var manualIP: String = ""

    var body: some View {
        List {
            Section {
                NavigationLink(destination: LMLinkMainView()) {
                    Label("LM Link Account", systemImage: "person.crop.circle.badge.checkmark")
                        .foregroundColor(.blue)
                }
            }

            Section {
                Picker("Discovery Method", selection: $selectedMethod) {
                    ForEach(DiscoveryMethod.allCases) { method in
                        Label(method.rawValue, systemImage: method.icon).tag(method)
                    }
                }
                .pickerStyle(.menu)

                methodInfoView
            } header: {
                Text("Connection Method")
            }

            Section {
                Button(action: {
                    performScan()
                }) {
                    HStack {
                        if discoveryService.isScanning {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Label(discoveryService.isScanning ? "Scanning..." : "Search for Devices", systemImage: "magnifyingglass")
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
        .refreshable {
            await performScan()
        }
    }

    @ViewBuilder
    private var methodInfoView: some View {
        switch selectedMethod {
        case .wifi:
            WiFiMethodView()
        case .lan:
            LANMethodView()
        case .ip:
            IPMethodView(ip: $manualIP)
        }
    }

    private func performScan() {
        Task {
            await discoveryService.performFullScan(method: selectedMethod, manualIP: selectedMethod == .ip ? manualIP : nil)
        }
    }
}

struct WiFiMethodView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Proximity Search")
                .font(.subheadline.bold())
            Text("Scans for LM Studio instances running on this device or nearby nodes with common ports (1234, 11434, 8080).")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct LANMethodView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Subnet Scan")
                .font(.subheadline.bold())
            Text("Deep scan of your local network subnet. This is the most thorough way to find any compatible model server on your network.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct IPMethodView: View {
    @Binding var ip: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Direct Connection")
                .font(.subheadline.bold())
            Text("Enter the static IP address of your LM Studio host if discovery fails.")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("192.168.1.XX", text: $ip)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.decimalPad)
        }
        .padding(.vertical, 4)
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
