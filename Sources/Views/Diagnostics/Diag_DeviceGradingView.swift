import SwiftUI
import Metal

struct Diag_DeviceGradingView: View {
    @State private var gradeResults: [GradeCategory] = []
    @State private var overallGrade: String = ""
    @State private var overallScore: Int = 0
    @State private var isGrading = false
    @State private var hasGraded = false

    struct GradeCategory: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let score: Int
        let maxScore: Int
        let details: String
        let status: ComponentStatus
    }

    enum ComponentStatus {
        case pass, warning, fail

        var color: Color {
            switch self {
            case .pass: return .green
            case .warning: return .orange
            case .fail: return .red
            }
        }
    }

    var body: some View {
        List {
            Section("Device Grade") {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 16)
                        Circle()
                            .trim(from: 0, to: CGFloat(overallScore) / 100.0)
                            .stroke(gradeColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.8), value: overallScore)
                        VStack {
                            Text(overallGrade.isEmpty ? "--" : overallGrade)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(gradeColor)
                            Text("\(overallScore)/100")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 150, height: 150)

                    Text(gradeDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            if !gradeResults.isEmpty {
                Section("Component Scores") {
                    ForEach(gradeResults) { cat in
                        HStack {
                            Image(systemName: cat.icon)
                                .foregroundStyle(cat.status.color)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(cat.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text("\(cat.score)/\(cat.maxScore)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(cat.status.color)
                                }
                                Text(cat.details)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                ProgressView(value: Double(cat.score), total: Double(cat.maxScore))
                                    .tint(cat.status.color)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    performGrading()
                } label: {
                    HStack {
                        if isGrading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: hasGraded ? "arrow.clockwise" : "star.fill")
                        }
                        Text(hasGraded ? "Re-grade Device" : "Grade Device")
                    }
                }
                .disabled(isGrading)
            }

            if hasGraded {
                Section {
                    let reportText = generateGradeReport()
                    ShareLink(item: reportText) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Grade Report")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Device Grading")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var gradeColor: Color {
        if overallScore >= 85 { return .green }
        if overallScore >= 70 { return .blue }
        if overallScore >= 50 { return .orange }
        return .red
    }

    private var gradeDescription: String {
        switch overallGrade {
        case "A+", "A": return "Excellent condition — like new"
        case "B+", "B": return "Good condition — minor wear"
        case "C+", "C": return "Fair condition — noticeable wear"
        case "D": return "Poor condition — significant issues"
        case "F": return "Critical issues detected"
        default: return "Tap Grade Device to start"
        }
    }

    private func performGrading() {
        isGrading = true
        var categories: [GradeCategory] = []

        UIDevice.current.isBatteryMonitoringEnabled = true
        let battLevel = UIDevice.current.batteryLevel
        let battScore: Int
        let battStatus: ComponentStatus
        if battLevel >= 0.8 {
            battScore = 15
            battStatus = .pass
        } else if battLevel >= 0.5 {
            battScore = 10
            battStatus = .warning
        } else {
            battScore = 5
            battStatus = .fail
        }
        categories.append(GradeCategory(name: "Battery", icon: "battery.100", score: battScore, maxScore: 15, details: battLevel >= 0 ? "Level: \(Int(battLevel * 100))%" : "Cannot read battery", status: battStatus))

        let pi = ProcessInfo.processInfo
        let thermalScore: Int
        let thermalStatus: ComponentStatus
        switch pi.thermalState {
        case .nominal: thermalScore = 15; thermalStatus = .pass
        case .fair: thermalScore = 10; thermalStatus = .warning
        case .serious: thermalScore = 5; thermalStatus = .fail
        case .critical: thermalScore = 0; thermalStatus = .fail
        @unknown default: thermalScore = 10; thermalStatus = .warning
        }
        categories.append(GradeCategory(name: "Thermal", icon: "thermometer.medium", score: thermalScore, maxScore: 15, details: "State: \(thermalStateStr(pi.thermalState))", status: thermalStatus))

        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = attrs[.systemSize] as? Int64,
           let free = attrs[.systemFreeSize] as? Int64 {
            let freePercent = Double(free) / Double(total) * 100
            let storageScore = freePercent > 20 ? 15 : freePercent > 10 ? 10 : 5
            let storageStatus: ComponentStatus = freePercent > 20 ? .pass : freePercent > 10 ? .warning : .fail
            categories.append(GradeCategory(name: "Storage", icon: "internaldrive.fill", score: storageScore, maxScore: 15, details: String(format: "%.1f%% free", freePercent), status: storageStatus))
        }

        let memGB = Double(pi.physicalMemory) / 1_073_741_824.0
        let memScore = memGB >= 4 ? 15 : memGB >= 3 ? 12 : memGB >= 2 ? 8 : 5
        let memStatus: ComponentStatus = memGB >= 3 ? .pass : memGB >= 2 ? .warning : .fail
        categories.append(GradeCategory(name: "Memory", icon: "memorychip", score: memScore, maxScore: 15, details: String(format: "%.1f GB RAM", memGB), status: memStatus))

        let gpuScore: Int
        let gpuStatus: ComponentStatus
        if let gpu = MTLCreateSystemDefaultDevice() {
            gpuScore = 15
            gpuStatus = .pass
            categories.append(GradeCategory(name: "GPU", icon: "gpu", score: gpuScore, maxScore: 15, details: gpu.name, status: gpuStatus))
        } else {
            gpuScore = 0
            gpuStatus = .fail
            categories.append(GradeCategory(name: "GPU", icon: "gpu", score: gpuScore, maxScore: 15, details: "Metal not available", status: gpuStatus))
        }

        let screenScale = UIScreen.main.nativeScale
        let screenScore = screenScale >= 3.0 ? 10 : screenScale >= 2.0 ? 8 : 5
        categories.append(GradeCategory(name: "Display", icon: "display", score: screenScore, maxScore: 10, details: "\(screenScale)x scale, \(UIScreen.main.maximumFramesPerSecond)Hz", status: screenScore >= 8 ? .pass : .warning))

        let cpuScore = pi.processorCount >= 6 ? 15 : pi.processorCount >= 4 ? 10 : 5
        categories.append(GradeCategory(name: "Processor", icon: "cpu", score: cpuScore, maxScore: 15, details: "\(pi.processorCount) cores", status: cpuScore >= 10 ? .pass : .warning))

        gradeResults = categories
        overallScore = categories.reduce(0) { $0 + $1.score }
        overallGrade = scoreToGrade(overallScore)
        isGrading = false
        hasGraded = true
    }

    private func scoreToGrade(_ score: Int) -> String {
        if score >= 95 { return "A+" }
        if score >= 85 { return "A" }
        if score >= 78 { return "B+" }
        if score >= 70 { return "B" }
        if score >= 60 { return "C+" }
        if score >= 50 { return "C" }
        if score >= 40 { return "D" }
        return "F"
    }

    private func thermalStateStr(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private func generateGradeReport() -> String {
        var text = "Device Grade Report\n"
        text += "Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n"
        text += "Overall Grade: \(overallGrade) (\(overallScore)/100)\n\n"
        for cat in gradeResults {
            text += "\(cat.name): \(cat.score)/\(cat.maxScore) - \(cat.details)\n"
        }
        return text
    }
}
