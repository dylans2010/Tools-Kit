import SwiftUI
import CoreTelephony

struct Diag_SIMInfoView: View {
    @State private var simSlots: [SIMSlotInfo] = []
    @State private var generalInfo: [(String, String)] = []

    struct SIMSlotInfo: Identifiable {
        let id: String
        let slotName: String
        let carrierName: String
        let mcc: String
        let mnc: String
        let isoCountry: String
        let allowsVOIP: Bool
        let radioTech: String
    }

    var body: some View {
        Form {
            Section("SIM Card Information") {
                VStack(spacing: 8) {
                    Image(systemName: "simcard.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text(simSlots.isEmpty ? "No SIM Detected" : "\(simSlots.count) SIM Slot\(simSlots.count > 1 ? "s" : "") Active")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            ForEach(simSlots) { slot in
                Section("SIM Slot: \(slot.slotName)") {
                    LabeledContent("Carrier") { Text(slot.carrierName) }
                    LabeledContent("Country") { Text(slot.isoCountry.uppercased()) }
                    LabeledContent("MCC") { Text(slot.mcc).monospacedDigit() }
                    LabeledContent("MNC") { Text(slot.mnc).monospacedDigit() }
                    LabeledContent("VoIP") {
                        Text(slot.allowsVOIP ? "Supported" : "Not Supported")
                            .foregroundStyle(slot.allowsVOIP ? .green : .red)
                    }
                    LabeledContent("Radio") {
                        Text(slot.radioTech)
                            .foregroundStyle(slot.radioTech.contains("LTE") || slot.radioTech.contains("NR") ? .green : .orange)
                    }
                }
            }

            if !generalInfo.isEmpty {
                Section("General") {
                    ForEach(generalInfo, id: \.0) { info in
                        LabeledContent(info.0) { Text(info.1).font(.caption) }
                    }
                }
            }

            Section("SIM Types") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Nano-SIM: Physical card (iPhone 5+)", systemImage: "simcard.fill")
                        .font(.caption)
                    Label("eSIM: Embedded digital SIM (iPhone XS+)", systemImage: "esim.fill")
                        .font(.caption)
                    Label("Dual SIM: Two numbers on one device", systemImage: "simcard.2.fill")
                        .font(.caption)
                    Label("iPhone 14+ (US): eSIM only, no tray", systemImage: "iphone.gen3")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { loadSIMInfo() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") }
                }
            }
        }
        .navigationTitle("SIM Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadSIMInfo() }
    }

    private func loadSIMInfo() {
        let info = CTTelephonyNetworkInfo()
        var slots: [SIMSlotInfo] = []
        var general: [(String, String)] = []

        if let providers = info.serviceSubscriberCellularProviders {
            let radios = info.serviceCurrentRadioAccessTechnology ?? [:]
            for (key, carrier) in providers {
                let radio = radios[key] ?? "Unknown"
                slots.append(SIMSlotInfo(
                    id: key,
                    slotName: key,
                    carrierName: carrier.carrierName ?? "Unknown",
                    mcc: carrier.mobileCountryCode ?? "N/A",
                    mnc: carrier.mobileNetworkCode ?? "N/A",
                    isoCountry: carrier.isoCountryCode ?? "N/A",
                    allowsVOIP: carrier.allowsVOIP,
                    radioTech: friendlyRadio(radio)
                ))
            }
        }

        general.append(("SIM Slots", "\(slots.count)"))
        general.append(("Dual SIM", slots.count > 1 ? "Yes" : "No"))
        general.append(("Data Service", info.dataServiceIdentifier ?? "Default"))

        simSlots = slots
        generalInfo = general
    }

    private func friendlyRadio(_ tech: String) -> String {
        if tech.contains("NR") { return "5G NR" }
        if tech.contains("LTE") { return "4G LTE" }
        if tech.contains("WCDMA") { return "3G WCDMA" }
        if tech.contains("HSDPA") { return "3G HSDPA" }
        if tech.contains("EDGE") { return "2G EDGE" }
        if tech.contains("GPRS") { return "2G GPRS" }
        return tech
    }
}
