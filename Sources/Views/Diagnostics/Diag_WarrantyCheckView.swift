import SwiftUI

struct Diag_WarrantyCheckView: View {
    @State private var imeiInput: String = ""
    @State private var serialInput: String = ""
    @State private var isLoading = false
    @State private var result: WarrantyResult?
    @State private var deviceAge: String = ""

    struct WarrantyResult {
        let status: String
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
                    Text("Check warranty, AppleCare, and coverage status via IMEI or Serial Number")
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
                    }
                }
            }

            Section("Check by IMEI") {
                TextField("IMEI (15 digits)", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .onChange(of: imeiInput) { _, newValue in
                        imeiInput = String(newValue.filter { $0.isNumber }.prefix(15))
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
                    Text(result.status)
                        .font(.headline)
                        .foregroundStyle(result.status.contains("Active") ? .green : .orange)
                        .padding(.vertical, 4)

                    ForEach(result.details, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
        let bootTime = Date().addingTimeInterval(-uptime)
        let fs = FileManager.default
        if let attrs = try? fs.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let creationDate = attrs[.systemSize] as? Date {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            deviceAge = formatter.localizedString(for: creationDate, relativeTo: Date())
        } else {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour]
            formatter.unitsStyle = .abbreviated
            deviceAge = "Uptime: \(formatter.string(from: uptime) ?? "N/A")"
        }
    }

    private func checkWarranty() {
        isLoading = true
        let identifier = imeiInput.isEmpty ? serialInput : imeiInput

        guard let url = URL(string: "https://api.imeicheck.net/v1/checks") else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let body: [String: Any] = [
            "deviceId": identifier,
            "serviceId": 6
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    result = WarrantyResult(
                        status: "Check Failed",
                        details: [
                            ("Error", error.localizedDescription),
                            ("Tip", "Visit checkcoverage.apple.com for manual lookup")
                        ]
                    )
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    result = WarrantyResult(
                        status: "Service Unavailable",
                        details: [
                            ("Identifier", identifier),
                            ("Note", "Try checkcoverage.apple.com for official warranty info")
                        ]
                    )
                    return
                }

                var details: [(String, String)] = [("Identifier", identifier)]
                if let warranty = json["warrantyStatus"] as? String { details.append(("Warranty", warranty)) }
                if let appleCare = json["appleCareEligible"] as? Bool { details.append(("AppleCare Eligible", appleCare ? "Yes" : "No")) }
                if let purchaseDate = json["estimatedPurchaseDate"] as? String { details.append(("Est. Purchase", purchaseDate)) }
                if let model = json["model"] as? String { details.append(("Model", model)) }
                if let coverage = json["coverageType"] as? String { details.append(("Coverage", coverage)) }

                let statusText = (json["warrantyStatus"] as? String)?.lowercased().contains("active") == true
                    ? "Warranty Active"
                    : "Warranty Status Retrieved"
                result = WarrantyResult(status: statusText, details: details)
            }
        }.resume()
    }
}
