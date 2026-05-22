import SwiftUI
import CoreBluetooth

struct Diag_BluetoothScannerView: View {
    @StateObject private var scanner = BluetoothScannerModel()

    var body: some View {
        Form {
            Section("Bluetooth Status") {
                HStack {
                    Image(systemName: scanner.isBluetoothOn ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        .font(.title2)
                        .foregroundStyle(scanner.isBluetoothOn ? .blue : .red)
                    VStack(alignment: .leading) {
                        Text(scanner.stateDescription)
                            .font(.headline)
                        Text(scanner.isScanning ? "Scanning..." : "Idle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Discovered Devices (\(scanner.discoveredDevices.count))") {
                if scanner.discoveredDevices.isEmpty {
                    Text(scanner.isScanning ? "Scanning for devices..." : "No devices found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(scanner.discoveredDevices) { device in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.name)
                                    .font(.subheadline.weight(.medium))
                                Text(device.identifier)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(device.rssi) dBm")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(rssiColor(device.rssi))
                        }
                    }
                }
            }

            Section {
                Button {
                    if scanner.isScanning { scanner.stopScan() } else { scanner.startScan() }
                } label: {
                    HStack {
                        Image(systemName: scanner.isScanning ? "stop.circle.fill" : "magnifyingglass.circle.fill")
                        Text(scanner.isScanning ? "Stop Scanning" : "Start Scanning")
                    }
                }
                .disabled(!scanner.isBluetoothOn)
            }
        }
        .navigationTitle("Bluetooth Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { scanner.stopScan() }
    }

    private func rssiColor(_ rssi: Int) -> Color {
        if rssi > -50 { return .green }
        if rssi > -70 { return .yellow }
        return .red
    }
}

struct DiscoveredBLEDevice: Identifiable {
    let id: String
    let name: String
    let identifier: String
    let rssi: Int
}

class BluetoothScannerModel: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var discoveredDevices: [DiscoveredBLEDevice] = []
    @Published var isBluetoothOn = false
    @Published var isScanning = false
    @Published var stateDescription = "Initializing..."

    private var centralManager: CBCentralManager!

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        discoveredDevices.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        isScanning = true
    }

    func stopScan() {
        centralManager.stopScan()
        isScanning = false
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothOn = true
            stateDescription = "Bluetooth On"
        case .poweredOff:
            isBluetoothOn = false
            stateDescription = "Bluetooth Off"
        case .unauthorized:
            isBluetoothOn = false
            stateDescription = "Unauthorized"
        case .unsupported:
            isBluetoothOn = false
            stateDescription = "Unsupported"
        case .resetting:
            stateDescription = "Resetting"
        case .unknown:
            stateDescription = "Unknown"
        @unknown default:
            stateDescription = "Unknown"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "Unknown Device"
        let id = peripheral.identifier.uuidString
        if !discoveredDevices.contains(where: { $0.id == id }) {
            discoveredDevices.append(DiscoveredBLEDevice(id: id, name: name, identifier: id, rssi: RSSI.intValue))
        }
    }
}
