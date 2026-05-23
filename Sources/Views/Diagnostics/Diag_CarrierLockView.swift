import SwiftUI
import CoreTelephony

struct Diag_CarrierLockView: View {
    @State private var lockStatus: LockStatus = .unknown
    @State private var checks: [(String, String, Bool)] = []
    @State private var carrierDetails: [(String, String)] = []
    @State private var imeiInput: String = ""
    @State private var isCheckingIMEI = false
    @State private var imeiResult: [(String, String)]?

    enum LockStatus {
        case locked, unlocked, unknown

        var color: Color {
            switch self {
            case .locked: return .red
            case .unlocked: return .green
            case .unknown: return .secondary
            }
        }

        var icon: String {
            switch self {
            case .locked: return "lock.fill"
            case .unlocked: return "lock.open.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }

        var title: String {
            switch self {
            case .locked: return "Carrier Locked"
            case .unlocked: return "Unlocked"
            case .unknown: return "Unknown"
            }
        }
    }

    var body: some View {
        Form {
            Section("Carrier Lock Status") {
                VStack(spacing: 12) {
                    Image(systemName: lockStatus.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(lockStatus.color)
                    Text(lockStatus.title)
                        .font(.headline)
                    Text(lockStatusDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("SIM & Carrier Detection") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(check.2 ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0)
                                .font(.subheadline.weight(.medium))
                            Text(check.1)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !carrierDetails.isEmpty {
                Section("Carrier Information") {
                    ForEach(carrierDetails, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                        }
                    }
                }
            }

            Section("IMEI Carrier Lock Check") {
                TextField("Enter IMEI (15 digits)", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .onChange(of: imeiInput) { _, newValue in
                        imeiInput = String(newValue.filter { $0.isNumber }.prefix(15))
                    }

                Button {
                    checkIMEILock()
                } label: {
                    HStack {
                        if isCheckingIMEI {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text("Check Lock via IMEI")
                    }
                }
                .disabled(imeiInput.count != 15 || isCheckingIMEI)

                if let results = imeiResult {
                    ForEach(results, id: \.0) { r in
                        LabeledContent(r.0) {
                            Text(r.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Understanding Carrier Locks") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Locked: Device only works with original carrier's SIM", systemImage: "lock.fill")
                        .font(.caption)
                    Label("Unlocked: Device works with any compatible carrier", systemImage: "lock.open.fill")
                        .font(.caption)
                    Label("Contact carrier or use IMEI to verify unlock eligibility", systemImage: "phone.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    detectLockStatus()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-detect")
                    }
                }
            }
        }
        .navigationTitle("Carrier Lock")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { detectLockStatus() }
    }

    private var lockStatusDescription: String {
        switch lockStatus {
        case .locked: return "This device appears to be locked to a specific carrier"
        case .unlocked: return "This device appears to accept any carrier SIM"
        case .unknown: return "Unable to definitively determine lock status"
        }
    }

    private func detectLockStatus() {
        var results: [(String, Bool)] = []
        var details: [(String, String)] = []
        let info = CTTelephonyNetworkInfo()

        if let providers = info.serviceSubscriberCellularProviders {
            let hasCarrier = providers.values.contains { $0.carrierName != nil }
            results.append(("SIM Detected", hasCarrier))

            for (slot, carrier) in providers {
                if let name = carrier.carrierName {
                    details.append(("Carrier (\(slot))", name))
                }
                if let mcc = carrier.mobileCountryCode {
                    details.append(("MCC (\(slot))", mcc))
                }
                if let mnc = carrier.mobileNetworkCode {
                    details.append(("MNC (\(slot))", mnc))
                }
                if let iso = carrier.isoCountryCode {
                    details.append(("Country (\(slot))", iso.uppercased()))
                }
                details.append(("VoIP (\(slot))", carrier.allowsVOIP ? "Yes" : "No"))
            }

            let multiSIM = providers.count > 1
            details.append(("Dual SIM", multiSIM ? "Yes (\(providers.count) slots)" : "Single SIM"))
        }

        if let radioTechs = info.serviceCurrentRadioAccessTechnology {
            let connected = !radioTechs.isEmpty
            results.append(("Cellular Connected", connected))
            for (slot, tech) in radioTechs {
                let techName = friendlyRadioName(tech)
                details.append(("Radio (\(slot))", techName))
            }
        }

        let hasDataCapability = info.serviceSubscriberCellularProviders?.values.contains { $0.mobileCountryCode != nil } ?? false
        results.append(("Data Capability", hasDataCapability))

        checks = results.map { ($0.0, $0.1 ? "Available" : "Not available", $0.1) }
        carrierDetails = details

        let passCount = results.filter { $0.1 }.count
        if passCount == results.count {
            lockStatus = .unlocked
        } else if passCount == 0 {
            lockStatus = .unknown
        } else {
            lockStatus = .unknown
        }
    }

    private func friendlyRadioName(_ tech: String) -> String {
        if tech.contains("NR") { return "5G NR" }
        if tech.contains("LTE") { return "4G LTE" }
        if tech.contains("WCDMA") { return "3G WCDMA" }
        if tech.contains("HSDPA") { return "3G HSDPA" }
        if tech.contains("EDGE") { return "2G EDGE" }
        if tech.contains("GPRS") { return "2G GPRS" }
        return tech
    }

    private func checkIMEILock() {
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else { return }
        isCheckingIMEI = true

        guard let url = URL(string: "https://api.imeicheck.net/v1/checks") else {
            isCheckingIMEI = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let body: [String: Any] = [
            "deviceId": imei,
            "serviceId": 2
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isCheckingIMEI = false

                if let error = error {
                    imeiResult = [
                        ("Error", error.localizedDescription),
                        ("Tip", "Contact your carrier directly for definitive lock status")
                    ]
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    imeiResult = [
                        ("IMEI", imei),
                        ("Status", "Service unavailable"),
                        ("Alternative", "Call carrier support or check carrier website with IMEI")
                    ]
                    return
                }

                var results: [(String, String)] = [("IMEI", imei)]
                if let lockStatus = json["simLock"] as? String {
                    results.append(("SIM Lock", lockStatus))
                }
                if let carrier = json["carrier"] as? String {
                    results.append(("Original Carrier", carrier))
                }
                if let model = json["model"] as? String {
                    results.append(("Model", model))
                }
                if let country = json["country"] as? String {
                    results.append(("Country of Origin", country))
                }

                imeiResult = results
            }
        }.resume()
    }
}
