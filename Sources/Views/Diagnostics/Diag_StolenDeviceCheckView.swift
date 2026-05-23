import SwiftUI

struct Diag_StolenDeviceCheckView: View {
    @State private var imeiInput: String = ""
    @State private var serialInput: String = ""
    @State private var isLoading = false
    @State private var result: StolenCheckResult?
    @State private var localChecks: [(String, String, Bool)] = []
    @State private var checkHistory: [(String, Bool?, Date)] = []

    private let service = IMEICheckService.shared

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
                    Text("Cross-reference device identifiers against global theft databases via live API")
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
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            if !checkHistory.isEmpty {
                Section("Check History") {
                    ForEach(checkHistory, id: \.0) { entry in
                        HStack {
                            Image(systemName: entry.1 == true ? "checkmark.shield.fill" : entry.1 == false ? "xmark.shield.fill" : "questionmark.circle.fill")
                                .foregroundStyle(entry.1 == true ? .green : entry.1 == false ? .red : .orange)
                            Text(entry.0)
                                .font(.caption.monospaced())
                            Spacer()
                            Text(entry.2, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
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

            Section("Report a Stolen Device") {
                Link(destination: URL(string: "https://support.apple.com/en-us/111894")!) {
                    Label("Apple - If your device is lost or stolen", systemImage: "safari.fill")
                        .font(.subheadline)
                }
                Link(destination: URL(string: "https://www.stolenphonechecker.org")!) {
                    Label("CTIA Stolen Phone Checker", systemImage: "safari.fill")
                        .font(.subheadline)
                }
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

        DiagnosticReportManager.shared.logIfEnabled(
            toolName: "Stolen Device Check",
            category: "Security",
            status: .info,
            details: "Local checks: \(results.filter { $0.2 }.count)/\(results.count) passed"
        )
    }

    private func performStolenCheck() {
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else { return }
        isLoading = true

        Task {
            let apiResult = await service.checkBlacklist(imei)

            await MainActor.run {
                isLoading = false

                var isClean: Bool?
                switch apiResult.status {
                case .clean: isClean = true
                case .blacklisted: isClean = false
                default: isClean = nil
                }

                let statusText = isClean == true ? "Device Appears Clean" : isClean == false ? "Device Reported Stolen/Lost" : "Status Unknown"
                result = StolenCheckResult(status: statusText, isClean: isClean, details: apiResult.details)
                checkHistory.insert((imei, isClean, Date()), at: 0)

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "Stolen Device Check",
                    category: "Security",
                    status: isClean == true ? .passed : isClean == false ? .failed : .warning,
                    details: "IMEI \(imei): \(statusText)"
                )
            }
        }
    }
}
