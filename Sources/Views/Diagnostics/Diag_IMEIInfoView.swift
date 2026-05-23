import SwiftUI
import CoreTelephony

struct Diag_IMEIInfoView: View {
    @State private var deviceIdentifiers: [(String, String)] = []
    @State private var imeiInput: String = ""
    @State private var isLoading = false
    @State private var isValidIMEI: Bool?
    @State private var validationResult: String?
    @State private var imeiStructure: IMEIStructure?
    @State private var tacResult: TACLookupResult?
    @State private var deviceInfoResult: DeviceInfoResult?
    @State private var lookupHistory: [(String, Date, String)] = []

    private let service = IMEICheckService.shared

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

            Section("IMEI Validator & Lookup") {
                TextField("Enter IMEI (15 digits)", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .textContentType(.none)
                    .autocorrectionDisabled()
                    .onChange(of: imeiInput) { _, newValue in
                        imeiInput = String(newValue.filter { $0.isNumber }.prefix(15))
                        if newValue.count < 15 {
                            isValidIMEI = nil
                            validationResult = nil
                            imeiStructure = nil
                            tacResult = nil
                            deviceInfoResult = nil
                        }
                    }

                if !imeiInput.isEmpty {
                    HStack {
                        Text("\(imeiInput.count)/15 digits")
                            .font(.caption)
                            .foregroundStyle(imeiInput.count == 15 ? .green : .secondary)
                        Spacer()
                        if imeiInput.count == 15 {
                            let valid = service.luhnValidate(imeiInput)
                            Text(valid ? "Valid checksum" : "Invalid checksum")
                                .font(.caption)
                                .foregroundStyle(valid ? .green : .red)
                        }
                    }
                }

                Button {
                    validateAndLookup()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.shield")
                        }
                        Text("Validate & Lookup IMEI")
                    }
                }
                .disabled(imeiInput.count < 15 || isLoading)

                if let result = validationResult, let valid = isValidIMEI {
                    HStack {
                        Image(systemName: valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(valid ? .green : .red)
                        Text(result)
                            .font(.subheadline)
                    }
                }
            }

            if let structure = imeiStructure {
                Section("IMEI Structure Breakdown") {
                    LabeledContent("TAC (Type Allocation Code)") {
                        Text(structure.tac).font(.caption.monospaced())
                    }
                    LabeledContent("Serial Number") {
                        Text(structure.serialNumber).font(.caption.monospaced())
                    }
                    LabeledContent("Check Digit") {
                        Text(structure.checkDigit).font(.caption.monospaced())
                    }
                    LabeledContent("Reporting Body") {
                        Text(structure.reportingBody).font(.caption)
                    }
                }
            }

            if let tac = tacResult {
                Section("TAC Database Result") {
                    if let error = tac.error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if let brand = tac.brand {
                        LabeledContent("Brand") { Text(brand).font(.caption) }
                    }
                    if let model = tac.model {
                        LabeledContent("Model") { Text(model).font(.caption) }
                    }
                    if let type = tac.deviceType {
                        LabeledContent("Device Type") { Text(type).font(.caption) }
                    }
                }
            }

            if let info = deviceInfoResult {
                Section("Device Information (API)") {
                    ForEach(info.details, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            if !lookupHistory.isEmpty {
                Section("Lookup History") {
                    ForEach(lookupHistory, id: \.0) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.0)
                                    .font(.caption.monospaced())
                                Text(entry.2)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.1, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("How to Find IMEI") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Dial *#06# on the Phone app", systemImage: "phone.fill")
                        .font(.subheadline)
                    Label("Settings \u{2192} General \u{2192} About \u{2192} IMEI", systemImage: "gearshape.fill")
                        .font(.subheadline)
                    Label("Printed on SIM tray or device back", systemImage: "simcard.fill")
                        .font(.subheadline)
                    Label("Check device packaging box barcode", systemImage: "barcode")
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }

            Section("Quick Links") {
                Link(destination: URL(string: "https://checkcoverage.apple.com")!) {
                    Label("Apple Coverage Check", systemImage: "safari.fill")
                        .font(.subheadline)
                }
                Link(destination: URL(string: "https://swappa.com/imei")!) {
                    Label("Swappa IMEI Check", systemImage: "safari.fill")
                        .font(.subheadline)
                }
                Link(destination: URL(string: "https://www.imeipro.info")!) {
                    Label("IMEIPro Lookup", systemImage: "safari.fill")
                        .font(.subheadline)
                }
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
        identifiers.append(("System", "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"))

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
                identifiers.append(("VoIP (\(slot))", carrier.allowsVOIP ? "Supported" : "Not Supported"))
            }
        }

        if let radioTechs = info.serviceCurrentRadioAccessTechnology {
            for (slot, tech) in radioTechs {
                identifiers.append(("Radio (\(slot))", friendlyRadioName(tech)))
            }
        }

        let processorCount = ProcessInfo.processInfo.processorCount
        identifiers.append(("CPU Cores", "\(processorCount)"))
        let ram = ProcessInfo.processInfo.physicalMemory
        identifiers.append(("RAM", String(format: "%.1f GB", Double(ram) / 1_073_741_824.0)))

        deviceIdentifiers = identifiers

        DiagnosticReportManager.shared.logIfEnabled(
            toolName: "IMEI Info",
            category: "Security",
            status: .info,
            details: "Gathered \(identifiers.count) device identifiers"
        )
    }

    private func validateAndLookup() {
        let digits = imeiInput.filter { $0.isNumber }
        guard digits.count == 15 else {
            validationResult = "IMEI must be exactly 15 digits"
            isValidIMEI = false
            return
        }

        let valid = service.luhnValidate(digits)
        isValidIMEI = valid
        validationResult = valid ? "Valid IMEI (Luhn check passed)" : "Invalid IMEI (Luhn check failed)"
        imeiStructure = service.parseIMEIStructure(digits)

        guard valid else {
            DiagnosticReportManager.shared.logIfEnabled(
                toolName: "IMEI Info",
                category: "Security",
                status: .failed,
                details: "IMEI \(digits) failed Luhn validation"
            )
            return
        }

        isLoading = true

        Task {
            async let tacLookup = service.lookupTAC(String(digits.prefix(8)))
            async let infoLookup = service.lookupDeviceInfo(digits)

            let tac = await tacLookup
            let info = await infoLookup

            await MainActor.run {
                tacResult = tac
                deviceInfoResult = info
                isLoading = false

                let summary = tac.model ?? tac.brand ?? "Lookup complete"
                lookupHistory.insert((digits, Date(), summary), at: 0)

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "IMEI Info",
                    category: "Security",
                    status: tac.error == nil ? .passed : .warning,
                    details: "IMEI \(digits): \(tac.brand ?? "Unknown") \(tac.model ?? "")"
                )
            }
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
}
