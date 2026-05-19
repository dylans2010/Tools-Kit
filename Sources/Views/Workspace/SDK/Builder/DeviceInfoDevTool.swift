import SwiftUI

struct DeviceInfoDevTool: DevTool {
    let id = "device-info"
    let name = "Device Info"
    let category = DevToolCategory.system
    let icon = "iphone"
    let description = "Detailed hardware and software info"

    func render() -> some View {
        DeviceInfoDevToolView()
    }
}

struct DeviceInfoDevToolView: View {
    @StateObject private var viewModel = DeviceInfoViewModel()

    var body: some View {
        List {
            Section("Identity") {
                VStack(spacing: 12) {
                    Image(systemName: viewModel.deviceIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                        .padding(.top)

                    Text(UIDevice.current.name)
                        .font(.title3.bold())

                    Text(viewModel.modelIdentifier)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom)
            }

            Section("Hardware Specifications") {
                InfoRow(label: "Processor", value: "\(ProcessInfo.processInfo.activeProcessorCount) Active Cores / \(ProcessInfo.processInfo.processorCount) Total", icon: "cpu")
                InfoRow(label: "Memory", value: viewModel.memory, icon: "memorychip")
                InfoRow(label: "Screen", value: viewModel.screenResolution, icon: "iphone.rear.camera")
                InfoRow(label: "Thermal State", value: viewModel.thermalState, icon: "thermometer.medium")
            }

            Section("Operating System") {
                InfoRow(label: "OS", value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)", icon: "applelogo")
                InfoRow(label: "Uptime", value: viewModel.uptime, icon: "clock")
                InfoRow(label: "Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off", icon: "battery.100.bolt")
            }

            Section("Localization & Identifiers") {
                InfoRow(label: "Language", value: Locale.current.language.languageCode?.identifier ?? "Unknown", icon: "character.bubble")
                InfoRow(label: "Region", value: Locale.current.region?.identifier ?? "Unknown", icon: "globe")
                InfoRow(label: "Identifier", value: UIDevice.current.identifierForVendor?.uuidString ?? "Unknown", icon: "person.badge.key")
            }

            Section {
                Button {
                    viewModel.copyAll()
                } label: {
                    Label("Copy System Report", systemImage: "doc.on.doc")
                }
            }
        }
        .navigationTitle("Device Info")
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
                .textSelection(.enabled)
        }
    }
}

class DeviceInfoViewModel: ObservableObject {
    var model: String = UIDevice.current.model
    var memory: String = ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory)

    var deviceIcon: String {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad: return "ipad"
        case .mac: return "macpro.gen3"
        default: return "iphone"
        }
    }

    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    var screenResolution: String {
        let bounds = UIScreen.main.nativeBounds
        return "\(Int(bounds.width)) x \(Int(bounds.height)) @ \(Int(UIScreen.main.scale))x"
    }

    var thermalState: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    var uptime: String {
        let uptime = ProcessInfo.processInfo.systemUptime
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    func copyAll() {
        let report = """
        Device Report
        -------------
        Model: \(model) (\(modelIdentifier))
        OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
        Processors: \(ProcessInfo.processInfo.processorCount)
        Memory: \(memory)
        Resolution: \(screenResolution)
        Language: \(Locale.current.identifier)
        """
        UIPasteboard.general.string = report
    }
}

#Preview {
    DeviceInfoDevToolView()
}
