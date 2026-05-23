import SwiftUI
import CoreLocation
import Network

struct Diag_SatelliteConnectivityView: View {
    @StateObject private var manager = SatelliteConnectivityManager()

    var body: some View {
        Form {
            Section("Satellite Status") {
                HStack {
                    Image(systemName: manager.satelliteIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(manager.statusColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(manager.statusTitle)
                            .font(.headline)
                        Text(manager.statusDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Device Compatibility") {
                LabeledContent("Satellite Hardware") {
                    Text(manager.hasSatelliteHardware ? "Available" : "Not Available")
                        .foregroundStyle(manager.hasSatelliteHardware ? .green : .red)
                }
                LabeledContent("Device Model") {
                    Text(manager.deviceModel)
                }
                LabeledContent("Minimum Required") {
                    Text("iPhone 14 or later")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("iOS Version") {
                    Text(UIDevice.current.systemVersion)
                }
            }

            Section("Network Fallback") {
                LabeledContent("WiFi Available") {
                    Text(manager.hasWiFi ? "Yes" : "No")
                        .foregroundStyle(manager.hasWiFi ? .green : .orange)
                }
                LabeledContent("Cellular Available") {
                    Text(manager.hasCellular ? "Yes" : "No")
                        .foregroundStyle(manager.hasCellular ? .green : .orange)
                }
                LabeledContent("Network Status") {
                    Text(manager.networkStatus)
                }
                LabeledContent("Satellite Needed") {
                    Text((!manager.hasWiFi && !manager.hasCellular) ? "Yes – No other connectivity" : "No – Standard network available")
                        .font(.caption)
                        .foregroundStyle((!manager.hasWiFi && !manager.hasCellular) ? .orange : .green)
                }
            }

            Section("Location Services") {
                LabeledContent("GPS Status") {
                    Text(CLLocationManager.locationServicesEnabled() ? "Enabled" : "Disabled")
                        .foregroundStyle(CLLocationManager.locationServicesEnabled() ? .green : .red)
                }
                LabeledContent("Heading Available") {
                    Text(CLLocationManager.headingAvailable() ? "Yes" : "No")
                        .foregroundStyle(CLLocationManager.headingAvailable() ? .green : .secondary)
                }
            }

            Section {
                Button {
                    manager.refresh()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Status")
                    }
                }
            }

            Section("About Satellite Connectivity") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emergency SOS via Satellite")
                        .font(.subheadline.weight(.medium))
                    Text("iPhone 14 and later models can connect to satellites when outside of cellular and Wi-Fi coverage. This feature enables Emergency SOS, Find My, and roadside assistance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Note: Satellite connectivity requires a clear view of the sky and may not be available in all regions.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Satellite Connectivity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { manager.refresh() }
    }
}

final class SatelliteConnectivityManager: ObservableObject {
    @Published var hasWiFi = false
    @Published var hasCellular = false
    @Published var networkStatus = "Checking..."
    @Published var hasSatelliteHardware = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "satellite.monitor")

    var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    var satelliteIcon: String {
        hasSatelliteHardware ? "satellite.fill" : "satellite"
    }

    var statusColor: Color {
        hasSatelliteHardware ? .green : .secondary
    }

    var statusTitle: String {
        hasSatelliteHardware ? "Satellite Capable" : "Not Supported"
    }

    var statusDescription: String {
        hasSatelliteHardware ? "This device supports satellite connectivity" : "Requires iPhone 14 or later"
    }

    init() {
        checkSatelliteCapability()
        startMonitoring()
    }

    func refresh() {
        checkSatelliteCapability()
    }

    private func checkSatelliteCapability() {
        let model = deviceModel
        // iPhone 14 series: iPhone15,x; iPhone 15: iPhone16,x; iPhone 16: iPhone17,x
        if model.hasPrefix("iPhone") {
            let numberPart = model.replacingOccurrences(of: "iPhone", with: "")
            if let majorStr = numberPart.split(separator: ",").first,
               let major = Int(majorStr) {
                hasSatelliteHardware = major >= 15
            }
        }
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.hasWiFi = path.usesInterfaceType(.wifi)
                self?.hasCellular = path.usesInterfaceType(.cellular)
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        self?.networkStatus = "Connected (WiFi)"
                    } else if path.usesInterfaceType(.cellular) {
                        self?.networkStatus = "Connected (Cellular)"
                    } else {
                        self?.networkStatus = "Connected"
                    }
                } else {
                    self?.networkStatus = "No Network – Satellite may activate"
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
