import SwiftUI
import CoreTelephony

struct Diag_IMEICarrierCompatView: View {
    @State private var imeiInput: String = ""
    @State private var isLoading = false
    @State private var deviceBands: [(String, String)]?
    @State private var localCarrierInfo: [(String, String)] = []
    @State private var compatResults: [(String, Bool, String)] = []

    private let service = IMEICheckService.shared

    private let majorCarrierBands: [(String, String, [String])] = [
        ("AT&T (US)", "antenna.radiowaves.left.and.right", ["B2", "B4", "B5", "B12", "B14", "B17", "B29", "B30", "B66", "n5", "n77", "n260"]),
        ("T-Mobile (US)", "antenna.radiowaves.left.and.right", ["B2", "B4", "B12", "B25", "B41", "B66", "B71", "n41", "n71", "n258", "n260", "n261"]),
        ("Verizon (US)", "antenna.radiowaves.left.and.right", ["B2", "B4", "B5", "B13", "B66", "n2", "n5", "n77", "n260", "n261"]),
        ("Vodafone (EU)", "globe.europe.africa.fill", ["B1", "B3", "B7", "B8", "B20", "B28", "B32", "B38", "n1", "n3", "n28", "n78"]),
        ("EE (UK)", "globe.europe.africa.fill", ["B1", "B3", "B7", "B20", "B28", "B38", "B40", "n1", "n3", "n28", "n78"]),
        ("Telstra (AU)", "globe.asia.australia.fill", ["B1", "B3", "B5", "B7", "B8", "B28", "B40", "n1", "n3", "n28", "n78"]),
        ("DoCoMo (JP)", "globe.asia.australia.fill", ["B1", "B3", "B19", "B21", "B28", "B42", "n78", "n79", "n257"]),
    ]

    var body: some View {
        Form {
            Section("Carrier Compatibility Check") {
                VStack(spacing: 8) {
                    Image(systemName: "simcard.2.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Band Compatibility Checker")
                        .font(.headline)
                    Text("Check if a device supports the frequency bands required by major carriers worldwide")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            if !localCarrierInfo.isEmpty {
                Section("Current Carrier") {
                    ForEach(localCarrierInfo, id: \.0) { info in
                        LabeledContent(info.0) { Text(info.1).font(.caption) }
                    }
                }
            }

            Section("IMEI Band Lookup") {
                TextField("15-digit IMEI number", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .onChange(of: imeiInput) { _, newValue in
                        imeiInput = String(newValue.filter { $0.isNumber }.prefix(15))
                    }

                Button {
                    lookupBands()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                        }
                        Text("Check Compatibility")
                    }
                }
                .disabled(imeiInput.count != 15 || isLoading)
            }

            if let bands = deviceBands {
                Section("Device Band Information") {
                    ForEach(bands, id: \.0) { band in
                        LabeledContent(band.0) {
                            Text(band.1).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                        }
                    }
                }
            }

            if !compatResults.isEmpty {
                Section("Carrier Compatibility") {
                    ForEach(compatResults, id: \.0) { result in
                        HStack {
                            Image(systemName: result.1 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.1 ? .green : .red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.0)
                                    .font(.subheadline.weight(.medium))
                                Text(result.2)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("How Band Compatibility Works") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Carriers use specific frequency bands for LTE/5G", systemImage: "waveform")
                        .font(.caption)
                    Label("Devices must support these bands to connect", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption)
                    Label("Missing key bands means poor or no service", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                    Label("5G NR bands are separate from LTE bands", systemImage: "5.circle.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Carrier Compatibility")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { gatherLocalCarrier() }
    }

    private func gatherLocalCarrier() {
        let info = CTTelephonyNetworkInfo()
        var details: [(String, String)] = []

        if let providers = info.serviceSubscriberCellularProviders {
            for (slot, carrier) in providers {
                if let name = carrier.carrierName { details.append(("Carrier (\(slot))", name)) }
                if let mcc = carrier.mobileCountryCode, let mnc = carrier.mobileNetworkCode {
                    details.append(("MCC/MNC (\(slot))", "\(mcc)/\(mnc)"))
                }
                if let iso = carrier.isoCountryCode { details.append(("Country (\(slot))", iso.uppercased())) }
            }
        }
        if let radioTechs = info.serviceCurrentRadioAccessTechnology {
            for (slot, tech) in radioTechs {
                details.append(("Radio (\(slot))", tech.replacingOccurrences(of: "CTRadioAccessTechnology", with: "")))
            }
        }
        localCarrierInfo = details
    }

    private func lookupBands() {
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else { return }
        isLoading = true

        Task {
            let apiResult = await service.lookupDeviceInfo(imei)

            await MainActor.run {
                isLoading = false
                deviceBands = apiResult.details.filter { $0.0 == "Bands" || $0.0 == "WiFi" || $0.0 == "Bluetooth" || $0.0 == "NFC" }

                let bandsString = apiResult.details.first(where: { $0.0 == "Bands" })?.1 ?? ""
                var results: [(String, Bool, String)] = []
                for carrier in majorCarrierBands {
                    let matched = carrier.2.filter { bandsString.contains($0) }
                    let compatible = matched.count >= carrier.2.count / 2
                    let desc = bandsString.isEmpty ? "Band data not available from API" : "\(matched.count)/\(carrier.2.count) required bands"
                    results.append((carrier.0, compatible || bandsString.isEmpty, desc))
                }
                compatResults = results

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "Carrier Compatibility",
                    category: "Connectivity",
                    status: .info,
                    details: "Band compatibility check for IMEI \(imei)"
                )
            }
        }
    }
}
