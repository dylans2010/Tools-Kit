import SwiftUI

struct Diag_BluetoothPacketView: View {
    var body: some View {
        List {
            Section("Bluetooth Traffic Monitor") {
                PacketRow(id: "0x01", type: "ADV_IND", size: "32", rssi: -65)
                PacketRow(id: "0x02", type: "SCAN_REQ", size: "12", rssi: -42)
                PacketRow(id: "0x03", type: "CONN_REQ", size: "28", rssi: -58)
            }

            Section("Protocol Stats") {
                LabeledContent("HCI Events", value: "1,242")
                LabeledContent("L2CAP Channels", value: "4")
            }
        }
        .navigationTitle("BT Packet Monitor")
    }
}

struct PacketRow: View {
    let id: String
    let type: String
    let size: String
    let rssi: Int
    var body: some View {
        HStack {
            Text(type)
                .font(.caption.bold())
                .padding(4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            Spacer()
            Text("\(size) B")
                .font(.caption)
            Text("\(rssi) dBm")
                .font(.caption)
                .foregroundStyle(rssi > -50 ? .green : .orange)
        }
    }
}
