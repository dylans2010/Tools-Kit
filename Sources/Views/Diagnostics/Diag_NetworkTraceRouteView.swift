import SwiftUI

struct Diag_NetworkTraceRouteView: View {
    var body: some View {
        List {
            Section("Hop Analysis") {
                HopRow(hop: 1, ip: "192.168.1.1", rtt: "1.2ms")
                HopRow(hop: 2, ip: "10.0.0.1", rtt: "5.4ms")
                HopRow(hop: 3, ip: "172.217.1.1", rtt: "12.8ms")
                HopRow(hop: 4, ip: "8.8.8.8", rtt: "14.2ms")
            }
        }
        .navigationTitle("Advanced TraceRoute")
    }
}

struct HopRow: View {
    let hop: Int
    let ip: String
    let rtt: String
    var body: some View {
        HStack {
            Text("\(hop)")
                .font(.caption.bold())
                .frame(width: 20)
            Text(ip)
                .font(.subheadline.monospaced())
            Spacer()
            Text(rtt)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
