import SwiftUI

struct EnergyImpactMonitorDevTool: DevTool {
    let id = "energy-impact-monitor"
    let name = "Energy Impact"
    let category = DevToolCategory.performance
    let icon = "bolt.fill"
    let description = "Monitor battery drain and power usage"

    func render() -> some View {
        EnergyImpactMonitorView()
    }
}

struct EnergyImpactMonitorView: View {
    @StateObject private var viewModel = EnergyImpactMonitorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Energy Impact",
                description: "Assess the power efficiency of your app by monitoring active background tasks and hardware usage.",
                icon: "bolt.fill"
            )
            .padding()

            Form {
                Section("Impact Score") {
                    HStack {
                        Text("\(Int(viewModel.impactScore))")
                            .font(.system(size: 40, weight: .bold))
                        Spacer()
                        StatusBadge(
                            text: viewModel.impactScore < 50 ? "Efficient" : "High Usage",
                            color: viewModel.impactScore < 50 ? .green : .orange
                        )
                    }
                }

                Section("Contributors") {
                    LabeledContent("CPU Intensity", value: viewModel.cpuIntensity)
                    LabeledContent("Network Activity", value: viewModel.networkActivity)
                    LabeledContent("Location Updates", value: viewModel.locationActive ? "Active" : "Idle")
                }
            }
        }
    }
}

class EnergyImpactMonitorViewModel: ObservableObject {
    @Published var impactScore: Double = 15
    @Published var cpuIntensity = "Low"
    @Published var networkActivity = "None"
    @Published var locationActive = false
}
