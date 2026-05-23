import SwiftUI
import CoreTelephony

struct Diag_CellularInfoView: View {
    @State private var carrierName: String = "Unknown"
    @State private var radioTechnology: String = "Unknown"
    @State private var isoCountryCode: String = "N/A"
    @State private var mobileCountryCode: String = "N/A"
    @State private var mobileNetworkCode: String = "N/A"
    @State private var allowsVOIP: Bool = false
    @State private var dataServiceIdentifier: String = "N/A"

    var body: some View {
        Form {
            Section("Carrier") {
                LabeledContent("Carrier Name") { Text(carrierName) }
                LabeledContent("Country Code") { Text(isoCountryCode) }
                LabeledContent("MCC") { Text(mobileCountryCode).monospacedDigit() }
                LabeledContent("MNC") { Text(mobileNetworkCode).monospacedDigit() }
                LabeledContent("VoIP Allowed") {
                    Text(allowsVOIP ? "Yes" : "No")
                        .foregroundStyle(allowsVOIP ? .green : .secondary)
                }
            }

            Section("Radio Access") {
                LabeledContent("Technology") { Text(radioTechnology) }
                LabeledContent("Data Service") { Text(dataServiceIdentifier).font(.caption) }
            }

            Section("Connection Type") {
                HStack {
                    Image(systemName: connectionIcon)
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(connectionLabel)
                            .font(.headline)
                        Text("Current radio access technology")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Cellular Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadCellularInfo() }
    }

    private var connectionIcon: String {
        if radioTechnology.contains("5G") { return "antenna.radiowaves.left.and.right" }
        if radioTechnology.contains("LTE") { return "antenna.radiowaves.left.and.right" }
        return "cellularbars"
    }

    private var connectionLabel: String {
        if radioTechnology.contains("NR") { return "5G" }
        if radioTechnology.contains("LTE") { return "4G LTE" }
        if radioTechnology.contains("WCDMA") || radioTechnology.contains("HSDPA") { return "3G" }
        return radioTechnology
    }

    private func loadCellularInfo() {
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrier = networkInfo.serviceSubscriberCellularProviders?.values.first {
            carrierName = carrier.carrierName ?? "Unknown"
            isoCountryCode = carrier.isoCountryCode ?? "N/A"
            mobileCountryCode = carrier.mobileCountryCode ?? "N/A"
            mobileNetworkCode = carrier.mobileNetworkCode ?? "N/A"
            allowsVOIP = carrier.allowsVOIP
        }
        if let tech = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            radioTechnology = tech.replacingOccurrences(of: "CTRadioAccessTechnology", with: "")
        }
        dataServiceIdentifier = networkInfo.dataServiceIdentifier ?? "N/A"
    }
}
