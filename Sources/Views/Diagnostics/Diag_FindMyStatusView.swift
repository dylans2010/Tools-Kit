import SwiftUI
import Security

struct Diag_FindMyStatusView: View {
    @State private var checks: [(String, String, CheckResult)] = []
    @State private var overallStatus: CheckResult = .unknown
    @State private var hasChecked = false

    enum CheckResult {
        case enabled, disabled, unknown

        var color: Color {
            switch self {
            case .enabled: return .orange
            case .disabled: return .green
            case .unknown: return .secondary
            }
        }
    }

    var body: some View {
        Form {
            Section("Find My iPhone Status") {
                VStack(spacing: 12) {
                    Image(systemName: overallStatus == .enabled ? "location.fill" : overallStatus == .disabled ? "location.slash.fill" : "questionmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(overallStatus == .enabled ? .blue : overallStatus == .disabled ? .green : .secondary)
                    Text(statusTitle)
                        .font(.headline)
                    Text(statusSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Detection Checks") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: iconFor(check.2))
                            .foregroundStyle(check.2.color)
                            .frame(width: 24)
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

            Section("IMEI Check") {
                NavigationLink {
                    IMEIActivationLockCheckView()
                } label: {
                    HStack {
                        Image(systemName: "number.circle.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Check via IMEI / Serial")
                                .font(.subheadline.weight(.medium))
                            Text("Verify activation lock status using device identifiers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Impact for Repair Shops") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Device cannot be erased without Apple ID", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Label("Activation Lock prevents re-setup after reset", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Label("Must be disabled before selling or servicing", systemImage: "wrench.and.screwdriver.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    runChecks()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-check Status")
                    }
                }
            }
        }
        .navigationTitle("Find My iPhone")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runChecks() }
    }

    private var statusTitle: String {
        switch overallStatus {
        case .enabled: return "Find My Likely Active"
        case .disabled: return "Find My Likely Inactive"
        case .unknown: return "Checking..."
        }
    }

    private var statusSubtitle: String {
        switch overallStatus {
        case .enabled: return "Activation Lock may be enabled on this device"
        case .disabled: return "No strong indicators of Find My activation"
        case .unknown: return "Running detection checks..."
        }
    }

    private func iconFor(_ result: CheckResult) -> String {
        switch result {
        case .enabled: return "exclamationmark.circle.fill"
        case .disabled: return "checkmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    private func runChecks() {
        var results: [(String, String, CheckResult)] = []
        let fm = FileManager.default

        let fmPaths = [
            "/var/mobile/Library/Preferences/com.apple.icloud.findmydeviced.plist",
            "/var/mobile/Library/Preferences/com.apple.findmy.plist"
        ]
        var fmPathFound = false
        for path in fmPaths {
            if fm.fileExists(atPath: path) {
                fmPathFound = true
                break
            }
        }
        results.append(("Find My Service Files", fmPathFound ? "Find My daemon configuration found" : "No Find My service files detected", fmPathFound ? .enabled : .unknown))

        let locationEnabled = checkLocationServicesActive()
        results.append(("Location Services", locationEnabled ? "Location services are active" : "Location services appear inactive", locationEnabled ? .enabled : .disabled))

        let icloudQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.apple.account.AppleIDAuthentication",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var icloudResult: CFTypeRef?
        let icloudStatus = SecItemCopyMatching(icloudQuery as CFDictionary, &icloudResult)
        let hasICloudAccount = icloudStatus == errSecSuccess || icloudStatus == errSecInteractionNotAllowed
        results.append(("iCloud Account", hasICloudAccount ? "iCloud account linked to device" : "No iCloud keychain entry detected", hasICloudAccount ? .enabled : .disabled))

        let activationLockPaths = [
            "/var/db/ConfigurationProfiles/Settings/com.apple.MobileBackup.plist"
        ]
        var activationLockIndicator = false
        for path in activationLockPaths {
            if fm.fileExists(atPath: path) {
                activationLockIndicator = true
                break
            }
        }
        results.append(("Activation Lock Indicator", activationLockIndicator ? "Activation Lock configuration detected" : "No activation lock files found", activationLockIndicator ? .enabled : .unknown))

        let pushPaths = ["/var/mobile/Library/Preferences/com.apple.apsd.plist"]
        var hasPush = false
        for path in pushPaths {
            if fm.fileExists(atPath: path) {
                hasPush = true
                break
            }
        }
        results.append(("Push Service", hasPush ? "Apple Push Notification active (required for Find My)" : "Push service not detected", hasPush ? .enabled : .disabled))

        checks = results
        let enabledCount = results.filter { $0.2 == .enabled }.count
        overallStatus = enabledCount >= 2 ? .enabled : enabledCount == 0 ? .disabled : .unknown
        hasChecked = true

        DiagnosticReportManager.shared.logIfEnabled(
            toolName: "Find My Status",
            category: "Security",
            status: overallStatus == .enabled ? .warning : overallStatus == .disabled ? .passed : .info,
            details: "Find My: \(statusTitle) (\(enabledCount)/\(results.count) indicators)"
        )
    }

    private func checkLocationServicesActive() -> Bool {
        let fm = FileManager.default
        let locationPaths = [
            "/var/mobile/Library/Preferences/com.apple.locationd.plist",
            "/var/root/Library/Preferences/com.apple.locationd.plist"
        ]
        for path in locationPaths {
            if fm.fileExists(atPath: path) { return true }
        }
        return false
    }
}

struct IMEIActivationLockCheckView: View {
    @State private var imeiInput: String = ""
    @State private var serialInput: String = ""
    @State private var isLoading = false
    @State private var result: ActivationCheckResult?

    struct ActivationCheckResult {
        let status: String
        let details: [(String, String)]
    }

    var body: some View {
        Form {
            Section("Enter Device Identifier") {
                TextField("IMEI (15 digits)", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                TextField("Serial Number (optional)", text: $serialInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
            }

            Section {
                Button {
                    checkActivationLock()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Image(systemName: "magnifyingglass")
                        Text("Check Activation Lock")
                    }
                }
                .disabled(imeiInput.count < 15 || isLoading)
            }

            if let result = result {
                Section("Result") {
                    Text(result.status)
                        .font(.headline)
                        .foregroundStyle(result.status.contains("OFF") ? .green : .orange)
                    ForEach(result.details, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Activation Lock Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func checkActivationLock() {
        isLoading = true
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else {
            result = ActivationCheckResult(
                status: "Invalid IMEI",
                details: [("Error", "IMEI must be 15 digits")]
            )
            isLoading = false
            return
        }

        let urlString = "https://api.imeicheck.net/v1/checks"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "deviceId": imei,
            "serviceId": 1
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    self.result = ActivationCheckResult(
                        status: "Check Failed",
                        details: [
                            ("Error", error.localizedDescription),
                            ("IMEI", imei),
                            ("Tip", "Use Apple's activation lock page or contact carrier for authoritative results")
                        ]
                    )
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.result = ActivationCheckResult(
                        status: "Service Unavailable",
                        details: [
                            ("IMEI Checked", imei),
                            ("Note", "External API returned unexpected response"),
                            ("Suggestion", "Try checking at Settings → [Apple ID] → Find My")
                        ]
                    )
                    return
                }

                var details: [(String, String)] = [("IMEI", imei)]
                if let status = json["activationLock"] as? String {
                    details.append(("Activation Lock", status))
                }
                if let model = json["model"] as? String {
                    details.append(("Model", model))
                }

                let statusText = (json["activationLock"] as? String)?.uppercased().contains("OFF") == true
                    ? "Activation Lock OFF"
                    : "Activation Lock Status Retrieved"

                self.result = ActivationCheckResult(status: statusText, details: details)
            }
        }.resume()
    }
}
