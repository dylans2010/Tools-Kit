import SwiftUI
import CoreTelephony
import Metal

struct Diag_FullDeviceReportView: View {
    @State private var reportSections: [ReportSection] = []
    @State private var isGenerating = false
    @State private var reportGenerated = false
    @State private var exportText: String = ""

    struct ReportSection: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let items: [(String, String)]
    }

    var body: some View {
        Form {
            Section("Comprehensive Device Report") {
                VStack(spacing: 8) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Full Device Diagnostic Report")
                        .font(.headline)
                    Text("Generate a complete report of all device hardware and software status for repair documentation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            if !reportGenerated {
                Section {
                    Button {
                        generateReport()
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "doc.badge.plus")
                            }
                            Text("Generate Full Report")
                        }
                    }
                    .disabled(isGenerating)
                }
            }

            ForEach(reportSections) { section in
                Section(section.title) {
                    ForEach(section.items, id: \.0) { item in
                        LabeledContent(item.0) {
                            Text(item.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            if reportGenerated {
                Section {
                    ShareLink(item: exportText) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Report")
                        }
                    }

                    Button {
                        generateReport()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Regenerate Report")
                        }
                    }
                }
            }
        }
        .navigationTitle("Full Device Report")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateReport() {
        isGenerating = true
        var sections: [ReportSection] = []
        var fullText = "=== DEVICE DIAGNOSTIC REPORT ===\n"
        fullText += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .medium))\n\n"

        var deviceItems: [(String, String)] = []
        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        deviceItems.append(("Model Identifier", modelId))
        deviceItems.append(("Device Model", UIDevice.current.model))
        deviceItems.append(("Device Name", UIDevice.current.name))
        deviceItems.append(("System", "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"))
        if let vid = UIDevice.current.identifierForVendor?.uuidString {
            deviceItems.append(("Vendor UUID", vid))
        }
        sections.append(ReportSection(title: "📱 Device Information", icon: "iphone", items: deviceItems))

        var cpuItems: [(String, String)] = []
        let pi = ProcessInfo.processInfo
        cpuItems.append(("CPU Cores", "\(pi.processorCount)"))
        cpuItems.append(("Active Cores", "\(pi.activeProcessorCount)"))
        cpuItems.append(("Physical RAM", formatBytes(pi.physicalMemory)))
        cpuItems.append(("Thermal State", thermalStateString(pi.thermalState)))
        cpuItems.append(("Low Power Mode", pi.isLowPowerModeEnabled ? "Enabled" : "Disabled"))
        cpuItems.append(("Uptime", formatUptime(pi.systemUptime)))
        sections.append(ReportSection(title: "⚡ Processor & Memory", icon: "cpu", items: cpuItems))

        var gpuItems: [(String, String)] = []
        if let gpu = MTLCreateSystemDefaultDevice() {
            gpuItems.append(("GPU Name", gpu.name))
            gpuItems.append(("Unified Memory", gpu.hasUnifiedMemory ? "Yes" : "No"))
            gpuItems.append(("Max Threads/Group", "\(gpu.maxThreadsPerThreadgroup)"))
            gpuItems.append(("Recommended Memory", formatBytes(UInt64(gpu.recommendedMaxWorkingSetSize))))
        } else {
            gpuItems.append(("GPU", "Metal not available"))
        }
        sections.append(ReportSection(title: "🎮 Graphics", icon: "gpu", items: gpuItems))

        var storageItems: [(String, String)] = []
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            let total = (attrs[.systemSize] as? Int64) ?? 0
            let free = (attrs[.systemFreeSize] as? Int64) ?? 0
            storageItems.append(("Total Storage", formatBytes(UInt64(total))))
            storageItems.append(("Free Space", formatBytes(UInt64(free))))
            storageItems.append(("Used Space", formatBytes(UInt64(total - free))))
            let usagePercent = total > 0 ? Double(total - free) / Double(total) * 100 : 0
            storageItems.append(("Usage", String(format: "%.1f%%", usagePercent)))
        }
        sections.append(ReportSection(title: "💾 Storage", icon: "internaldrive.fill", items: storageItems))

        UIDevice.current.isBatteryMonitoringEnabled = true
        var batteryItems: [(String, String)] = []
        let level = UIDevice.current.batteryLevel
        batteryItems.append(("Battery Level", level >= 0 ? "\(Int(level * 100))%" : "Unknown"))
        let state: String = {
            switch UIDevice.current.batteryState {
            case .unknown: return "Unknown"
            case .unplugged: return "Unplugged"
            case .charging: return "Charging"
            case .full: return "Full"
            @unknown default: return "Unknown"
            }
        }()
        batteryItems.append(("Battery State", state))
        batteryItems.append(("Low Power Mode", pi.isLowPowerModeEnabled ? "On" : "Off"))
        sections.append(ReportSection(title: "🔋 Battery", icon: "battery.100", items: batteryItems))

        var displayItems: [(String, String)] = []
        let screen = UIScreen.main
        displayItems.append(("Resolution", "\(Int(screen.bounds.width))×\(Int(screen.bounds.height)) pt"))
        displayItems.append(("Native Resolution", "\(Int(screen.nativeBounds.width))×\(Int(screen.nativeBounds.height)) px"))
        displayItems.append(("Scale", "\(screen.scale)x"))
        displayItems.append(("Brightness", String(format: "%.0f%%", screen.brightness * 100)))
        if #available(iOS 15.0, *) {
            displayItems.append(("Max FPS", "\(screen.maximumFramesPerSecond) Hz"))
        }
        sections.append(ReportSection(title: "🖥️ Display", icon: "display", items: displayItems))

        var networkItems: [(String, String)] = []
        let netInfo = CTTelephonyNetworkInfo()
        if let providers = netInfo.serviceSubscriberCellularProviders {
            for (slot, carrier) in providers {
                if let name = carrier.carrierName {
                    networkItems.append(("Carrier (\(slot))", name))
                }
            }
        }
        if let radios = netInfo.serviceCurrentRadioAccessTechnology {
            for (slot, tech) in radios {
                networkItems.append(("Radio (\(slot))", tech))
            }
        }
        sections.append(ReportSection(title: "📡 Network", icon: "antenna.radiowaves.left.and.right", items: networkItems))

        reportSections = sections

        for section in sections {
            fullText += "--- \(section.title) ---\n"
            for item in section.items {
                fullText += "\(item.0): \(item.1)\n"
            }
            fullText += "\n"
        }
        exportText = fullText

        isGenerating = false
        reportGenerated = true
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func thermalStateString(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        return d > 0 ? "\(d)d \(h)h \(m)m" : "\(h)h \(m)m"
    }
}
