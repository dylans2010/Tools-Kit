import SwiftUI
import Security
import Metal

struct Diag_DeviceAuthenticityView: View {
    @State private var checks: [(String, String, AuthStatus)] = []
    @State private var overallGenuine: AuthStatus = .unknown
    @State private var hasChecked = false

    enum AuthStatus {
        case genuine, suspicious, unknown

        var color: Color {
            switch self {
            case .genuine: return .green
            case .suspicious: return .red
            case .unknown: return .secondary
            }
        }

        var icon: String {
            switch self {
            case .genuine: return "checkmark.seal.fill"
            case .suspicious: return "exclamationmark.triangle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }

    var body: some View {
        Form {
            Section("Device Authenticity") {
                VStack(spacing: 12) {
                    Image(systemName: overallGenuine.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(overallGenuine.color)
                    Text(overallGenuine == .genuine ? "Genuine Apple Device" : overallGenuine == .suspicious ? "Possible Non-Genuine" : "Checking...")
                        .font(.headline)
                    Text(overallGenuine == .genuine ? "All hardware checks passed" : "Some hardware checks raised flags")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Hardware Verification") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2.icon)
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

            Section {
                Button {
                    runVerification()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-verify")
                    }
                }
            }
        }
        .navigationTitle("Device Authenticity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runVerification() }
    }

    private func runVerification() {
        var results: [(String, String, AuthStatus)] = []

        var systemInfo = utsname()
        uname(&systemInfo)
        let modelId = Mirror(reflecting: systemInfo.machine).children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
        let knownPrefixes = ["iPhone", "iPad", "iPod", "AppleTV", "Watch", "AudioAccessory", "MacBook", "Mac", "iMac", "arm64"]
        let isKnownModel = knownPrefixes.contains { modelId.hasPrefix($0) }
        results.append(("Model Identifier", "Model: \(modelId)", isKnownModel ? .genuine : .suspicious))

        let device = MTLCreateSystemDefaultDevice()
        let hasGPU = device != nil
        var gpuName = "Not available"
        if let gpu = device {
            gpuName = gpu.name
        }
        let isAppleGPU = gpuName.lowercased().contains("apple")
        results.append(("GPU Verification", "GPU: \(gpuName)", (hasGPU && isAppleGPU) ? .genuine : hasGPU ? .genuine : .suspicious))

        let processorCount = ProcessInfo.processInfo.processorCount
        let isValidCPU = processorCount >= 2 && processorCount <= 16
        results.append(("CPU Core Count", "\(processorCount) cores detected", isValidCPU ? .genuine : .suspicious))

        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let memGB = Double(physicalMemory) / 1_073_741_824.0
        let isValidMem = memGB >= 1.0 && memGB <= 16.0
        results.append(("RAM Verification", String(format: "%.1f GB", memGB), isValidMem ? .genuine : .suspicious))

        let seAttrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave
        ]
        var seError: Unmanaged<CFError>?
        let seKey = SecKeyCreateRandomKey(seAttrs as CFDictionary, &seError)
        let hasSE = seKey != nil || seError == nil
        results.append(("Secure Enclave", hasSE ? "Hardware security chip present" : "Secure Enclave test inconclusive", hasSE ? .genuine : .unknown))

        let screenScale = UIScreen.main.nativeScale
        let knownScales: [CGFloat] = [1.0, 2.0, 3.0]
        let isValidScale = knownScales.contains(screenScale)
        results.append(("Display Scale", "\(screenScale)x native scale", isValidScale ? .genuine : .suspicious))

        let systemVersion = UIDevice.current.systemVersion
        let majorVersion = Int(systemVersion.components(separatedBy: ".").first ?? "0") ?? 0
        let validOS = majorVersion >= 12 && majorVersion <= 25
        results.append(("OS Verification", "iOS \(systemVersion)", validOS ? .genuine : .suspicious))

        let sysName = UIDevice.current.systemName
        results.append(("System Name", sysName, sysName == "iOS" || sysName == "iPadOS" ? .genuine : .suspicious))

        checks = results
        let suspiciousCount = results.filter { $0.2 == .suspicious }.count
        overallGenuine = suspiciousCount == 0 ? .genuine : suspiciousCount >= 3 ? .suspicious : .unknown
        hasChecked = true

        DiagnosticReportManager.shared.logIfEnabled(
            toolName: "Device Authenticity",
            category: "Security",
            status: overallGenuine == .genuine ? .passed : overallGenuine == .suspicious ? .failed : .warning,
            details: "Authenticity: \(overallGenuine == .genuine ? "Genuine" : overallGenuine == .suspicious ? "Suspicious" : "Unknown") (\(suspiciousCount) flags)"
        )
    }
}
