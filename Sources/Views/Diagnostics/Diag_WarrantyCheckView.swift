import SwiftUI

struct Diag_WarrantyCheckView: View {
    @State private var imeiInput: String = ""
    @State private var serialInput: String = ""
    @State private var isLoading = false
    @State private var result: WarrantyDisplayResult?
    @State private var deviceAge: String = ""
    @State private var checkHistory: [(String, String, Date)] = []

    private let service = IMEICheckService.shared

    struct WarrantyDisplayResult {
        let status: String
        let isActive: Bool?
        let details: [(String, String)]
    }

    var body: some View {
        Form {
            Section("Warranty & AppleCare Check") {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Apple Warranty Status")
                        .font(.headline)
                    Text("Check warranty, AppleCare, and coverage status via IMEI or Serial Number using live API")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Device Details") {
                let model = deviceModelIdentifier()
                LabeledContent("Model") { Text(model).font(.caption.monospaced()) }
                LabeledContent("iOS Version") { Text(UIDevice.current.systemVersion) }
                LabeledContent("Estimated Age") { Text(deviceAge.isEmpty ? "Calculating..." : deviceAge) }
                if let vendorID = UIDevice.current.identifierForVendor?.uuidString {
                    LabeledContent("Vendor UUID") {
                        Text(vendorID)
                            .font(.caption2.monospaced())
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .textSelection(.enabled)
                    }
                }
                LabeledContent("CPU Cores") { Text("\(ProcessInfo.processInfo.processorCount)") }
                LabeledContent("RAM") {
                    Text(String(format: "%.1f GB", Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0))
                }
            }

            Section("Check by IMEI") {
                TextField("IMEI (15 digits)", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .onChange(of: imeiInput) { _, newValue in
                        imeiInput = String(newValue.filter { $0.isNumber }.prefix(15))
                    }

                if !imeiInput.isEmpty && imeiInput.count == 15 {
                    let valid = service.luhnValidate(imeiInput)
                    Text(valid ? "Valid IMEI" : "Invalid checksum")
                        .font(.caption)
                        .foregroundStyle(valid ? .green : .red)
                }

                TextField("Serial Number (optional)", text: $serialInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)

                Button {
                    checkWarranty()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.seal")
                        }
                        Text("Check Warranty Status")
                    }
                }
                .disabled((imeiInput.count < 15 && serialInput.isEmpty) || isLoading)
            }

            if let result = result {
                Section("Warranty Result") {
                    HStack(spacing: 12) {
                        Image(systemName: result.isActive == true ? "checkmark.seal.fill" : "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(result.isActive == true ? .green : .orange)
                        Text(result.status)
                            .font(.headline)
                            .foregroundStyle(result.isActive == true ? .green : .orange)
                    }
                    .padding(.vertical, 4)

                    ForEach(result.details, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            if !checkHistory.isEmpty {
                Section("Check History") {
                    ForEach(checkHistory, id: \.0) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.0)
                                    .font(.caption.monospaced())
                                Text(entry.1)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.2, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("Coverage Types") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Limited Warranty: 1 year from purchase", systemImage: "1.circle.fill")
                        .font(.caption)
                    Label("AppleCare+: Extended coverage (2-3 years)", systemImage: "2.circle.fill")
                        .font(.caption)
                    Label("AppleCare+ with Theft & Loss", systemImage: "3.circle.fill")
                        .font(.caption)
                    Label("Consumer Law Coverage (varies by region)", systemImage: "4.circle.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Check Manually") {
                Link(destination: URL(string: "https://checkcoverage.apple.com")!) {
                    HStack {
                        Image(systemName: "safari.fill")
                            .foregroundStyle(.blue)
                        Text("Apple Coverage Check Website")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "https://support.apple.com/en-us/111900")!) {
                    HStack {
                        Image(systemName: "safari.fill")
                            .foregroundStyle(.blue)
                        Text("Apple Support - Check Your Coverage")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Warranty Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { estimateDeviceAge() }
    }

    private func deviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return Mirror(reflecting: systemInfo.machine).children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
    }

    private func estimateDeviceAge() {
        let uptime = ProcessInfo.processInfo.systemUptime
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour]
        formatter.unitsStyle = .abbreviated
        deviceAge = "Uptime: \(formatter.string(from: uptime) ?? "N/A")"
    }

    private func checkWarranty() {
        isLoading = true
        let identifier = imeiInput.isEmpty ? serialInput : imeiInput

        Task {
            let apiResult = await service.checkWarranty(identifier)

            await MainActor.run {
                isLoading = false

                let statusText = apiResult.active == true ? "Warranty Active" : "Warranty Status Retrieved"
                result = WarrantyDisplayResult(
                    status: statusText,
                    isActive: apiResult.active,
                    details: apiResult.details
                )

                checkHistory.insert((identifier, statusText, Date()), at: 0)

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "Warranty Check",
                    category: "System",
                    status: apiResult.active == true ? .passed : .warning,
                    details: "\(identifier): \(statusText)"
                )
            }
        }
    }
}
