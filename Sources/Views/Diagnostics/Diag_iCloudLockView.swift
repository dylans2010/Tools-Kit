import SwiftUI
import Security

struct Diag_iCloudLockView: View {
    @State private var checks: [(String, String, LockIndicator)] = []
    @State private var overallStatus: LockIndicator = .unknown
    @State private var imeiInput: String = ""
    @State private var isCheckingIMEI = false
    @State private var imeiCheckResult: [(String, String)]?

    enum LockIndicator {
        case locked, clear, unknown

        var color: Color {
            switch self {
            case .locked: return .orange
            case .clear: return .green
            case .unknown: return .secondary
            }
        }
    }

    var body: some View {
        Form {
            Section("iCloud Activation Lock") {
                VStack(spacing: 12) {
                    Image(systemName: overallStatus == .locked ? "icloud.fill" : overallStatus == .clear ? "checkmark.icloud.fill" : "icloud.slash")
                        .font(.system(size: 52))
                        .foregroundStyle(overallStatus.color)
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

            Section("Local Detection") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Circle()
                            .fill(check.2.color)
                            .frame(width: 8, height: 8)
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

            Section("IMEI-Based Check") {
                TextField("Enter IMEI (15 digits)", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .onChange(of: imeiInput) { _, newValue in
                        imeiInput = String(newValue.filter { $0.isNumber }.prefix(15))
                    }

                Button {
                    checkIMEIiCloudLock()
                } label: {
                    HStack {
                        if isCheckingIMEI {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "icloud.and.arrow.up")
                        }
                        Text("Check iCloud Lock via IMEI")
                    }
                }
                .disabled(imeiInput.count != 15 || isCheckingIMEI)

                if let results = imeiCheckResult {
                    ForEach(results, id: \.0) { r in
                        LabeledContent(r.0) {
                            Text(r.1).font(.caption)
                        }
                    }
                }
            }

            Section("What is iCloud Activation Lock?") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activation Lock is a security feature tied to Find My iPhone. When enabled, the device requires the original Apple ID and password to:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("Erase the device", systemImage: "trash.fill")
                        .font(.caption)
                    Label("Reactivate after factory reset", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                    Label("Turn off Find My iPhone", systemImage: "location.slash.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    runLocalChecks()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-check")
                    }
                }
            }
        }
        .navigationTitle("iCloud Lock Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runLocalChecks() }
    }

    private var statusTitle: String {
        switch overallStatus {
        case .locked: return "iCloud Account Linked"
        case .clear: return "No iCloud Lock Detected"
        case .unknown: return "Status Uncertain"
        }
    }

    private var statusSubtitle: String {
        switch overallStatus {
        case .locked: return "Device has an active iCloud account — Activation Lock likely enabled"
        case .clear: return "No strong indicators of iCloud lock found on this device"
        case .unknown: return "Could not definitively determine iCloud lock status"
        }
    }

    private func runLocalChecks() {
        var results: [(String, String, LockIndicator)] = []

        let accountQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.apple.account.AppleIDAuthentication",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var accountResult: CFTypeRef?
        let accountStatus = SecItemCopyMatching(accountQuery as CFDictionary, &accountResult)
        let hasAccount = accountStatus == errSecSuccess || accountStatus == errSecInteractionNotAllowed
        results.append(("Apple ID Keychain Entry", hasAccount ? "iCloud account token found in keychain" : "No iCloud account keychain entry", hasAccount ? .locked : .clear))

        let icloudPaths = [
            "/var/mobile/Library/Preferences/com.apple.icloud.findmydeviced.plist",
            "/var/mobile/Library/Preferences/MobileMeAccounts.plist"
        ]
        var icloudFilesFound = false
        for path in icloudPaths {
            if FileManager.default.fileExists(atPath: path) {
                icloudFilesFound = true
                break
            }
        }
        results.append(("iCloud Service Files", icloudFilesFound ? "iCloud configuration files present" : "No iCloud configuration files found", icloudFilesFound ? .locked : .unknown))

        let identityCertQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]
        var certResult: CFTypeRef?
        let certStatus = SecItemCopyMatching(identityCertQuery as CFDictionary, &certResult)
        var appleCertFound = false
        if certStatus == errSecSuccess, let certs = certResult as? [[String: Any]] {
            for cert in certs {
                if let label = cert[kSecAttrLabel as String] as? String,
                   label.lowercased().contains("apple") || label.lowercased().contains("icloud") {
                    appleCertFound = true
                    break
                }
            }
        }
        results.append(("Apple Certificates", appleCertFound ? "Apple identity certificates found" : "No Apple identity certificates detected", appleCertFound ? .locked : .unknown))

        let backupPaths = ["/var/mobile/Library/Preferences/com.apple.MobileBackup.plist"]
        var backupFound = false
        for path in backupPaths {
            if FileManager.default.fileExists(atPath: path) {
                backupFound = true
                break
            }
        }
        results.append(("iCloud Backup Config", backupFound ? "Backup configuration present" : "No backup configuration", backupFound ? .locked : .unknown))

        checks = results
        let lockedCount = results.filter { $0.2 == .locked }.count
        overallStatus = lockedCount >= 2 ? .locked : lockedCount == 0 ? .clear : .unknown
    }

    private func checkIMEIiCloudLock() {
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
            "serviceId": 1
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isCheckingIMEI = false

                if let error = error {
                    imeiCheckResult = [
                        ("Error", error.localizedDescription),
                        ("Suggestion", "Check at Settings → [your name] → Find My")
                    ]
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    imeiCheckResult = [
                        ("IMEI", imei),
                        ("Status", "Service unavailable — try again later")
                    ]
                    return
                }

                var results: [(String, String)] = [("IMEI", imei)]
                if let fmiStatus = json["findMyIphone"] as? String {
                    results.append(("Find My iPhone", fmiStatus))
                }
                if let lockStatus = json["activationLock"] as? String {
                    results.append(("Activation Lock", lockStatus))
                }
                if let model = json["model"] as? String {
                    results.append(("Model", model))
                }
                imeiCheckResult = results
            }
        }.resume()
    }
}
