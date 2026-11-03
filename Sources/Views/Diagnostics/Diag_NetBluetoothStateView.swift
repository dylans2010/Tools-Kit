import SwiftUI
import CoreBluetooth

final class DiagNewBTStateModel: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var state = "Initialising…"
    private var central: CBCentralManager!

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: state = "Powered On"
        case .poweredOff: state = "Powered Off"
        case .unauthorized: state = "Unauthorized (check Info.plist NSBluetoothAlwaysUsageDescription)"
        case .unsupported: state = "Unsupported"
        case .resetting: state = "Resetting"
        case .unknown: state = "Unknown"
        @unknown default: state = "Unknown"
        }
    }
}

struct Diag_NetBluetoothStateView: View {
    @StateObject private var model = DiagNewBTStateModel()

    var body: some View {
        Form {
            Section("Bluetooth") {
                LabeledContent("State") { Text(model.state) }
            }
        }
        .navigationTitle("Bluetooth State")
        .navigationBarTitleDisplayMode(.inline)
    }
}
