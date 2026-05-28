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
        Form {
            Section(header: Text("Impact Score")) {
                HStack {
                    Text("\(Int(viewModel.impactScore))")
                        .font(.system(size: 40, weight: .bold))
                    Spacer()
                    Text(viewModel.impactScore < 50 ? "Efficient" : "High Usage")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(viewModel.impactScore < 50 ? Color.green : Color.orange, in: RoundedRectangle(cornerRadius: 4))
                }
            }

            Section(header: Text("Contributors")) {
                LabeledContent("CPU Intensity", value: viewModel.cpuIntensity)
                LabeledContent("Network Activity", value: viewModel.networkActivity)
                LabeledContent("Location Updates", value: viewModel.locationActive ? "Active" : "Idle")
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

#Preview {
    EnergyImpactMonitorView()
}
