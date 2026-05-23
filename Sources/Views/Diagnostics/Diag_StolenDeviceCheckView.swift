import SwiftUI

struct Diag_StolenDeviceCheckView: View {
    @State private var imeiInput: String = ""
    @State private var serialInput: String = ""
    @State private var isLoading = false
    @State private var result: StolenCheckResult?
    @State private var localChecks: [(String, String, Bool)] = []

    struct StolenCheckResult {
        let status: String
        let isClean: Bool?
        let details: [(String, String)]
    }

    var body: some View {
        Form {
            Section("Stolen Device Check") {
                VStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Device Theft Database Lookup")
                        .font(.headline)
                    Text("Cross-reference device identifiers against global theft databases")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Local Theft Protection") {
                ForEach(localChecks, id: \.0) { check in
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

            Section("IMEI Database Lookup") {
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
                    performStolenCheck()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass.circle.fill")
                        }
                        Text("Check Stolen Database")
                    }
                }
                .disabled(imeiInput.count != 15 || isLoading)
            }

            if let result = result {
                Section("Result") {
                    HStack(spacing: 12) {
                        Image(systemName: result.isClean == true ? "checkmark.shield.fill" : result.isClean == false ? "xmark.shield.fill" : "questionmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(result.isClean == true ? .green : result.isClean == false ? .red : .orange)
                        Text(result.status)
                            .font(.headline)
                    }
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

            Section("Databases Checked") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("GSMA IMEI Database", systemImage: "globe")
                        .font(.caption)
                    Label("Carrier blacklist registries", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption)
                    Label("Law enforcement databases (where available)", systemImage: "shield.fill")
                        .font(.caption)
                    Label("International lost/stolen registries", systemImage: "map.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Stolen Device Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runLocalChecks() }
    }

    private func runLocalChecks() {
        var results: [(String, String, Bool)] = []
        let fm = FileManager.default

        let stolenModePaths = ["/var/mobile/Library/Preferences/com.apple.stolendeviceprotection.plist"]
        var hasStolenProtection = false
        for path in stolenModePaths {
            if fm.fileExists(atPath: path) {
                hasStolenProtection = true
                break
            }
        }
        results.append(("Stolen Device Protection", hasStolenProtection ? "Stolen Device Protection configuration detected" : "Feature check requires iOS 17.3+", hasStolenProtection))

        let findMyPaths = ["/var/mobile/Library/Preferences/com.apple.icloud.findmydeviced.plist"]
        var findMyActive = false
        for path in findMyPaths {
            if fm.fileExists(atPath: path) {
                findMyActive = true
                break
            }
        }
        results.append(("Find My iPhone", findMyActive ? "Find My service files present" : "Find My not detected", findMyActive))

        let eraseContentPaths = ["/var/mobile/Library/Preferences/com.apple.purplebuddy.plist"]
        var wasReset = false
        for path in eraseContentPaths {
            if fm.fileExists(atPath: path) {
                wasReset = true
                break
            }
        }
        results.append(("Setup Assistant", wasReset ? "Setup assistant data present" : "No setup assistant artifacts", !wasReset))

        localChecks = results
    }

    private func performStolenCheck() {
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else { return }
        isLoading = true

        guard let url = URL(string: "https://api.imeicheck.net/v1/checks") else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let body: [String: Any] = [
            "deviceId": imei,
            "serviceId": 12
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    result = StolenCheckResult(
                        status: "Check Failed",
                        isClean: nil,
                        details: [
                            ("Error", error.localizedDescription),
                            ("IMEI", imei),
                            ("Alternative", "Report stolen devices at your local carrier or police station")
                        ]
                    )
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    result = StolenCheckResult(
                        status: "Service Unavailable",
                        isClean: nil,
                        details: [("IMEI", imei), ("Note", "External verification service did not respond")]
                    )
                    return
                }

                var details: [(String, String)] = [("IMEI", imei)]
                var isClean: Bool?

                if let blacklistStatus = json["blacklistStatus"] as? String {
                    let upper = blacklistStatus.uppercased()
                    if upper.contains("CLEAN") || upper.contains("CLEAR") {
                        isClean = true
                    } else if upper.contains("BLACK") || upper.contains("STOLEN") || upper.contains("LOST") {
                        isClean = false
                    }
                    details.append(("Blacklist Status", blacklistStatus))
                }

                if let model = json["model"] as? String { details.append(("Model", model)) }
                if let brand = json["brand"] as? String { details.append(("Brand", brand)) }

                let statusText = isClean == true ? "Device Appears Clean" : isClean == false ? "Device Reported Stolen/Lost" : "Status Unknown"

                result = StolenCheckResult(status: statusText, isClean: isClean, details: details)
            }
        }.resume()
    }
}
