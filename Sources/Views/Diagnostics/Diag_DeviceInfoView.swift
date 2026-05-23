import SwiftUI

struct Diag_DeviceInfoView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        Form {
            Section("Device") {
                LabeledContent("Model") { Text(service.deviceModel) }
                LabeledContent("Name") { Text(service.deviceName) }
                LabeledContent("Model Identifier") { Text(service.deviceModelIdentifier).font(.caption) }
                LabeledContent("Vendor ID") {
                    Text(service.identifierForVendor)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Section("System") {
                LabeledContent("OS") { Text(service.systemName) }
                LabeledContent("Version") { Text(service.systemVersion) }
                LabeledContent("Kernel") { Text(service.kernelVersion).font(.caption) }
                LabeledContent("Hostname") { Text(service.hostname).font(.caption) }
                LabeledContent("Uptime") { Text(service.formattedUptime).monospacedDigit() }
            }

            Section("Hardware") {
                LabeledContent("Processor Cores") { Text("\(service.processorCount)") }
                LabeledContent("Active Cores") { Text("\(service.activeProcessorCount)") }
                LabeledContent("Physical Memory") {
                    Text(service.formattedBytes(Int64(service.physicalMemory)))
                }
                LabeledContent("Thermal State") {
                    Text(service.thermalState)
                        .foregroundStyle(thermalColor)
                }
            }

            Section("Display") {
                LabeledContent("Screen Bounds") {
                    Text("\(Int(service.screenBounds.width))×\(Int(service.screenBounds.height))")
                }
                LabeledContent("Native Resolution") {
                    Text("\(Int(service.screenNativeBounds.width))×\(Int(service.screenNativeBounds.height))")
                }
                LabeledContent("Scale Factor") { Text("\(service.screenScale, specifier: "%.0f")x") }
                LabeledContent("Brightness") {
                    Text("\(Int(service.screenBrightness * 100))%")
                }
            }
        }
        .navigationTitle("Device Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var thermalColor: Color {
        switch service.thermalState {
        case "Nominal": return .green
        case "Fair": return .yellow
        case "Serious": return .orange
        case "Critical": return .red
        default: return .secondary
        }
    }
}
