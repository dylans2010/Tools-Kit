import SwiftUI
import CoreTelephony

struct Diag_NetCarrierDetailView: View {
    @State private var rows: [(String, String)] = []

    var body: some View {
        Form {
            Section("Carriers") {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, r in LabeledContent(r.0) { Text(r.1).font(.caption) } }
            }
            Section { Button("Refresh") { load() } }
        }
        .navigationTitle("Carrier Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        let info = CTTelephonyNetworkInfo()
        var out: [(String, String)] = []
        if let providers = info.serviceSubscriberCellularProviders {
            for (_, p) in providers {
                out.append(("Carrier", p.carrierName ?? "Unknown"))
                out.append(("ISO Country", p.isoCountryCode ?? "Unknown"))
                out.append(("MCC", p.mobileCountryCode ?? "Unknown"))
                out.append(("MNC", p.mobileNetworkCode ?? "Unknown"))
                out.append(("VoIP", p.allowsVOIP ? "Allowed" : "Not allowed"))
            }
        }
        if out.isEmpty { out.append(("Carrier", "No carrier info available")) }
        rows = out
    }
}
