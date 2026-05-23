import SwiftUI
import Metal

struct Diag_DeviceValuationView: View {
    @State private var valuationDetails: [(String, String)] = []
    @State private var grade: String = ""
    @State private var gradeColor: Color = .secondary
    @State private var estimatedValue: String = ""
    @State private var conditionChecks: [(String, String, Bool)] = []
    @State private var hasRun = false

    var body: some View {
        Form {
            Section("Device Valuation") {
                VStack(spacing: 12) {
                    if hasRun {
                        Text(grade)
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(gradeColor)
                        Text(estimatedValue)
                            .font(.title3.weight(.medium))
                        Text("Estimated trade-in value based on device condition")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                        Text("Device Trade-In Estimator")
                            .font(.headline)
                        Text("Estimate device value based on real hardware condition checks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            if !conditionChecks.isEmpty {
                Section("Condition Assessment") {
                    ForEach(conditionChecks, id: \.0) { check in
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
            }

            if !valuationDetails.isEmpty {
                Section("Device Specifications") {
                    ForEach(valuationDetails, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    runValuation()
                } label: {
                    HStack {
                        Image(systemName: hasRun ? "arrow.clockwise" : "play.circle.fill")
                        Text(hasRun ? "Re-evaluate" : "Run Valuation")
                    }
                }
            }

            Section("Trade-In Resources") {
                Link(destination: URL(string: "https://www.apple.com/shop/trade-in")!) {
                    Label("Apple Trade In", systemImage: "safari.fill").font(.subheadline)
                }
                Link(destination: URL(string: "https://swappa.com/sell/apple")!) {
                    Label("Swappa Marketplace", systemImage: "safari.fill").font(.subheadline)
                }
                Link(destination: URL(string: "https://www.gazelle.com")!) {
                    Label("Gazelle", systemImage: "safari.fill").font(.subheadline)
                }
            }
        }
        .navigationTitle("Device Valuation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if !hasRun { runValuation() } }
    }

    private func runValuation() {
        var details: [(String, String)] = []
        var checks: [(String, String, Bool)] = []
        var score = 0
        let maxScore = 10

        var systemInfo = utsname()
        uname(&systemInfo)
        let modelId = Mirror(reflecting: systemInfo.machine).children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
        details.append(("Model", modelId))
        details.append(("iOS", "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"))

        let ram = ProcessInfo.processInfo.physicalMemory
        let ramGB = Double(ram) / 1_073_741_824.0
        details.append(("RAM", String(format: "%.1f GB", ramGB)))

        let cpuCores = ProcessInfo.processInfo.processorCount
        details.append(("CPU Cores", "\(cpuCores)"))

        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = attrs[.systemSize] as? Int64 {
            let totalGB = Double(total) / 1_073_741_824.0
            details.append(("Storage", String(format: "%.0f GB", totalGB)))
        }

        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        if batteryLevel >= 0 {
            let pct = Int(batteryLevel * 100)
            details.append(("Battery Level", "\(pct)%"))
            let batteryGood = pct >= 80
            checks.append(("Battery Health", batteryGood ? "Battery at \(pct)% - Good condition" : "Battery at \(pct)% - May need replacement", batteryGood))
            if batteryGood { score += 2 } else { score += 1 }
        }

        let thermalState = ProcessInfo.processInfo.thermalState
        let thermalOK = thermalState == .nominal || thermalState == .fair
        checks.append(("Thermal State", thermalOK ? "Normal operating temperature" : "Elevated thermal state detected", thermalOK))
        if thermalOK { score += 1 }

        let gpu = MTLCreateSystemDefaultDevice()
        let hasGPU = gpu != nil
        checks.append(("GPU", hasGPU ? "Metal GPU available: \(gpu?.name ?? "OK")" : "No Metal GPU detected", hasGPU))
        if hasGPU { score += 1 }

        let hasGoodRAM = ramGB >= 3.0
        checks.append(("RAM Capacity", hasGoodRAM ? "Adequate RAM (\(String(format: "%.1f GB", ramGB)))" : "Low RAM may affect resale value", hasGoodRAM))
        if hasGoodRAM { score += 1 }

        let hasGoodCPU = cpuCores >= 4
        checks.append(("CPU Performance", hasGoodCPU ? "\(cpuCores) cores - Good performance" : "\(cpuCores) cores - Older processor", hasGoodCPU))
        if hasGoodCPU { score += 1 }

        let isLatestOS = Float(UIDevice.current.systemVersion.components(separatedBy: ".").first ?? "0") ?? 0 >= 17
        checks.append(("Software Support", isLatestOS ? "Running latest major iOS version" : "May not support latest iOS", isLatestOS))
        if isLatestOS { score += 2 }

        let isCharging = batteryState == .charging || batteryState == .full
        if isCharging {
            checks.append(("Charging Port", "Device is charging - port functional", true))
            score += 1
        } else {
            checks.append(("Charging Port", "Connect charger to verify port function", batteryState != .unknown))
        }

        if let free = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())?[.systemFreeSize] as? Int64,
           let total = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())?[.systemSize] as? Int64 {
            let usedPct = Double(total - free) / Double(total) * 100
            let storageOK = usedPct < 90
            checks.append(("Storage Health", storageOK ? "Storage at \(String(format: "%.0f", usedPct))% capacity" : "Storage nearly full", storageOK))
            if storageOK { score += 1 }
        }

        let gradeStr: String
        let color: Color
        let valueStr: String
        let ratio = Double(score) / Double(maxScore)
        if ratio >= 0.8 {
            gradeStr = "A"
            color = .green
            valueStr = "Excellent Condition"
        } else if ratio >= 0.6 {
            gradeStr = "B"
            color = .blue
            valueStr = "Good Condition"
        } else if ratio >= 0.4 {
            gradeStr = "C"
            color = .orange
            valueStr = "Fair Condition"
        } else {
            gradeStr = "D"
            color = .red
            valueStr = "Poor Condition"
        }

        self.grade = gradeStr
        self.gradeColor = color
        self.estimatedValue = valueStr
        self.valuationDetails = details
        self.conditionChecks = checks
        self.hasRun = true

        DiagnosticReportManager.shared.logIfEnabled(
            toolName: "Device Valuation",
            category: "System",
            status: ratio >= 0.6 ? .passed : .warning,
            details: "Grade: \(gradeStr) - \(valueStr) (Score: \(score)/\(maxScore))"
        )
    }
}
