import SwiftUI
import CoreTelephony

struct Diag_IMEIInfoView: View {
    @State private var deviceIdentifiers: [(String, String)] = []
    @State private var imeiInput: String = ""
    @State private var isLoading = false
    @State private var validationResult: String?
    @State private var isValidIMEI: Bool?

    var body: some View {
        Form {
            Section("Device Identifiers") {
                if deviceIdentifiers.isEmpty {
                    ProgressView("Gathering identifiers...")
                } else {
                    ForEach(deviceIdentifiers, id: \.0) { item in
                        LabeledContent(item.0) {
                            Text(item.1)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            Section("IMEI Validator") {
                TextField("Enter IMEI (15 digits)", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .textContentType(.none)
                    .autocorrectionDisabled()

                Button {
                    validateIMEI()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.shield")
                        Text("Validate IMEI")
                    }
                }
                .disabled(imeiInput.count < 15)

                if let result = validationResult, let valid = isValidIMEI {
                    HStack {
                        Image(systemName: valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(valid ? .green : .red)
                        Text(result)
                            .font(.subheadline)
                    }
                }
            }

            Section("IMEI Structure") {
                if imeiInput.count == 15, let valid = isValidIMEI, valid {
                    let tac = String(imeiInput.prefix(8))
                    let serial = String(imeiInput.dropFirst(8).prefix(6))
                    let checkDigit = String(imeiInput.suffix(1))
                    LabeledContent("TAC (Type Allocation Code)") {
                        Text(tac).font(.caption.monospaced())
                    }
                    LabeledContent("Serial Number") {
                        Text(serial).font(.caption.monospaced())
                    }
                    LabeledContent("Check Digit") {
                        Text(checkDigit).font(.caption.monospaced())
                    }
                    LabeledContent("Reporting Body") {
                        Text(tacReportingBody(tac: tac))
                            .font(.caption)
                    }
                } else {
                    Text("Enter a valid 15-digit IMEI to see breakdown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("How to Find IMEI") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Dial *#06# on the Phone app", systemImage: "phone.fill")
                        .font(.subheadline)
                    Label("Settings → General → About → IMEI", systemImage: "gearshape.fill")
                        .font(.subheadline)
                    Label("Printed on SIM tray or device back", systemImage: "simcard.fill")
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("IMEI Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { gatherIdentifiers() }
    }

    private func gatherIdentifiers() {
        var identifiers: [(String, String)] = []

        var systemInfo = utsname()
        uname(&systemInfo)
        let modelId = Mirror(reflecting: systemInfo.machine).children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
        identifiers.append(("Model Identifier", modelId))
        identifiers.append(("Device Model", UIDevice.current.model))
        identifiers.append(("Device Name", UIDevice.current.name))

        if let vendorID = UIDevice.current.identifierForVendor?.uuidString {
            identifiers.append(("Vendor UUID", vendorID))
        }

        let info = CTTelephonyNetworkInfo()
        if let carriers = info.serviceSubscriberCellularProviders {
            for (slot, carrier) in carriers {
                if let name = carrier.carrierName {
                    identifiers.append(("Carrier (\(slot))", name))
                }
                if let mcc = carrier.mobileCountryCode {
                    identifiers.append(("MCC (\(slot))", mcc))
                }
                if let mnc = carrier.mobileNetworkCode {
                    identifiers.append(("MNC (\(slot))", mnc))
                }
                if let iso = carrier.isoCountryCode {
                    identifiers.append(("ISO Country (\(slot))", iso.uppercased()))
                }
            }
        }

        identifiers.append(("System", "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"))

        deviceIdentifiers = identifiers
    }

    private func validateIMEI() {
        let digits = imeiInput.filter { $0.isNumber }
        guard digits.count == 15 else {
            validationResult = "IMEI must be exactly 15 digits"
            isValidIMEI = false
            return
        }
        let valid = luhnCheck(digits)
        isValidIMEI = valid
        validationResult = valid ? "Valid IMEI (Luhn check passed)" : "Invalid IMEI (Luhn check failed)"
    }

    private func luhnCheck(_ number: String) -> Bool {
        let digits = number.compactMap { Int(String($0)) }
        guard digits.count == 15 else { return false }
        var sum = 0
        for (index, digit) in digits.enumerated() {
            if index % 2 == 0 {
                sum += digit
            } else {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            }
        }
        return sum % 10 == 0
    }

    private func tacReportingBody(tac: String) -> String {
        guard let first2 = Int(String(tac.prefix(2))) else { return "Unknown" }
        switch first2 {
        case 01: return "PTCRB (USA)"
        case 35: return "BABT (UK)"
        case 86: return "TAF (China)"
        case 91: return "MSAI (India)"
        case 44: return "Japan (JATE/TELEC)"
        case 45: return "South Korea (KCC)"
        case 50: return "Malaysia (MCMC)"
        default: return "GSMA Registered"
        }
    }
}
