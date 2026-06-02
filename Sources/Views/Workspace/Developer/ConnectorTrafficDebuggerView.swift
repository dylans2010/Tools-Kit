import SwiftUI

struct ConnectorTrafficDebuggerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var isMonitoring = false

    var body: some View {
        VStack(spacing: 0) {
            header

            List(store.connectorTraffic) { packet in
                TrafficPacketRow(packet: packet)
            }
            .listStyle(.plain)

            if store.connectorTraffic.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    Text("No traffic detected.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !isMonitoring {
                        Button("Start Debugger") { startMonitoring() }
                            .buttonStyle(.bordered)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .navigationTitle("Traffic Debugger")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isMonitoring ? "Stop" : "Start") {
                    isMonitoring ? stopMonitoring() : startMonitoring()
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Label("\(store.connectorTraffic.count) Packets", systemImage: "bolt.fill")
            Spacer()
            Button("Clear") { store.saveConnectorTraffic([]) }
                .font(.caption2.bold())
        }
        .padding()
        .background(Color.primary.opacity(0.05))
    }

    private func startMonitoring() {
        isMonitoring = true
        simulatePacket()
    }

    private func stopMonitoring() {
        isMonitoring = false
    }

    private func simulatePacket() {
        guard isMonitoring else { return }
        let packet = TrafficPacket(
            method: ["GET", "POST", "PUT"].randomElement()!,
            path: "/v1/api/sync",
            statusCode: 200,
            duration: 0.15
        )
        var updated = store.connectorTraffic
        updated.insert(packet, at: 0)
        if updated.count > 50 { updated.removeLast() }
        store.saveConnectorTraffic(updated)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            simulatePacket()
        }
    }
}

private struct TrafficPacketRow: View {
    let packet: TrafficPacket

    var body: some View {
        HStack {
            Text(packet.method)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(width: 45)

            VStack(alignment: .leading, spacing: 2) {
                Text(packet.path).font(.system(size: 11, weight: .semibold, design: .monospaced))
                Text(packet.timestamp, style: .time).font(.system(size: 9)).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(packet.statusCode)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green)
                Text(String(format: "%.0fms", packet.duration * 1000))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
