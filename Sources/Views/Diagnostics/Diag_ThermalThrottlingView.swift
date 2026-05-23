import SwiftUI

struct Diag_ThermalThrottlingView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: thermalIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(thermalColor)

                    Text(service.thermalState)
                        .font(.title2.weight(.bold))

                    Text(thermalMessage)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Performance Impact") {
                LabeledContent("CPU Throttling") {
                    Text(isThrottled ? "Active" : "None")
                        .foregroundStyle(isThrottled ? .red : .green)
                }
                LabeledContent("GPU Throttling") {
                    Text(isThrottled ? "Active" : "None")
                        .foregroundStyle(isThrottled ? .red : .green)
                }
                LabeledContent("Charging Speed", value: isThrottled ? "Reduced" : "Normal")
            }

            Section("Historical Peak") {
                LabeledContent("Max Recorded", value: "Serious")
            }
        }
        .navigationTitle("Thermal Throttling")
    }

    private var thermalIcon: String {
        switch service.thermalState {
        case "Nominal": return "thermometer.low"
        case "Fair": return "thermometer.medium"
        case "Serious": return "thermometer.high"
        case "Critical": return "thermometer.sun.fill"
        default: return "thermometer"
        }
    }

    private var thermalColor: Color {
        switch service.thermalState {
        case "Nominal": return .green
        case "Fair": return .yellow
        case "Serious": return .orange
        case "Critical": return .red
        default: return .gray
        }
    }

    private var isThrottled: Bool {
        service.thermalState == "Serious" || service.thermalState == "Critical"
    }

    private var thermalMessage: String {
        switch service.thermalState {
        case "Nominal": return "Device is operating within normal temperature ranges."
        case "Fair": return "Slight temperature elevation. Performance remains normal."
        case "Serious": return "Performance is being reduced to lower temperature."
        case "Critical": return "Significant performance reduction. Device may shut down."
        default: return "Unknown thermal state."
        }
    }
}
