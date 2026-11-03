import SwiftUI
import CoreTelephony

struct Diag_NetRadioTechView: View {
    @State private var tech = "Unknown"

    var body: some View {
        Form {
            Section("Radio") {
                LabeledContent("Technology") { Text(tech).font(.caption) }
                LabeledContent("Generation") { Text(tech.contains("NR") ? "5G" : tech.contains("LTE") ? "4G LTE" : "Unknown") }
            }
            Section { Button("Refresh") { load() } }
        }
        .navigationTitle("Radio Technology")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        let info = CTTelephonyNetworkInfo()
        if let dict = info.serviceCurrentRadioAccessTechnology, let first = dict.values.first {
            tech = first.replacingOccurrences(of: "CTRadioAccessTechnology", with: "")
        }
    }
}
