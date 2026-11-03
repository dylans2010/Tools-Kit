import SwiftUI
import CoreBluetooth

/// Live Bluetooth scan. iOS apps cannot read raw HCI packets or L2CAP
/// traffic from the sandbox, so the old hardcoded packet table was fake.
/// This view does what an app can actually do: scan with CoreBluetooth
/// and report the real peripherals it discovers, with their live RSSI.
final class DiagBLEScanner: NSObject, ObservableObject, CBCentralManagerDelegate {
    struct Peripheral: Identifiable {
        let id: UUID
        var name: String
        var rssi: Int
        var serviceUUIDs: [String]
        var manufacturerHex: String?
        var lastSeen: Date
    }

    @Published var peripherals: [Peripheral] = []
    @Published var stateText = "Starting…"
    @Published var isScanning = false

    private var central: CBCentralManager!

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard central.state == .poweredOn else {
            stateText = "Bluetooth is \(central.state == .poweredOff ? "off" : "unavailable") — enable Bluetooth to scan."
            return
        }
        peripherals.removeAll()
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        isScanning = true
        stateText = "Scanning for BLE peripherals…"
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
        stateText = peripherals.isEmpty ? "Scan stopped — no peripherals found." : "Scan stopped — \(peripherals.count) peripheral(s) found."
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: stateText = "Bluetooth on — ready to scan."
        case .poweredOff: stateText = "Bluetooth is off."
        case .unauthorized: stateText = "Bluetooth permission not granted."
        case .unsupported: stateText = "Bluetooth LE is not supported on this device."
        default: stateText = "Bluetooth unavailable."
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let uuids = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map(\.uuidString) ?? []
        var manufacturerHex: String?
        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            manufacturerHex = data.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " ")
        }
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? "Unknown"
        if let index = peripherals.firstIndex(where: { $0.id == peripheral.identifier }) {
            peripherals[index].rssi = RSSI.intValue
            peripherals[index].name = name
            peripherals[index].serviceUUIDs = uuids
            peripherals[index].manufacturerHex = manufacturerHex
            peripherals[index].lastSeen = Date()
        } else {
            peripherals.append(Peripheral(id: peripheral.identifier, name: name, rssi: RSSI.intValue, serviceUUIDs: uuids, manufacturerHex: manufacturerHex, lastSeen: Date()))
        }
        peripherals.sort { $0.rssi > $1.rssi }
    }
}

struct Diag_BluetoothPacketView: View {
    @StateObject private var scanner = DiagBLEScanner()

    var body: some View {
        List {
            Section("Bluetooth Traffic Monitor") {
                Text(scanner.stateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if scanner.peripherals.isEmpty && !scanner.isScanning {
                    Text("Tap Scan to discover nearby BLE peripherals.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(scanner.peripherals) { peripheral in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(peripheral.name)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(peripheral.rssi) dBm")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(peripheral.rssi > -50 ? .green : .orange)
                        }
                        Text(peripheral.id.uuidString)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                        if !peripheral.serviceUUIDs.isEmpty {
                            Text("Services: \(peripheral.serviceUUIDs.joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if let hex = peripheral.manufacturerHex {
                            Text("Manufacturer data: \(hex)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Protocol Stats") {
                LabeledContent("Discovered Peripherals", value: "\(scanner.peripherals.count)")
                LabeledContent("Strongest RSSI", value: scanner.peripherals.map(\.rssi).max().map { "\($0) dBm" } ?? "—")
            }

            Section {
                Button {
                    if scanner.isScanning { scanner.stopScan() } else { scanner.startScan() }
                } label: {
                    HStack {
                        Image(systemName: scanner.isScanning ? "stop.circle.fill" : "play.circle.fill")
                        Text(scanner.isScanning ? "Stop Scan" : "Scan for BLE Peripherals")
                    }
                }
            }

            Section {
                Text("Raw HCI packets and L2CAP channels are not exposed to iOS apps, so this tool reports live CoreBluetooth discoveries instead of a packet capture. Values above come from the current scan, not a stored table.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("BT Packet Monitor")
        .onDisappear { scanner.stopScan() }
    }
}
