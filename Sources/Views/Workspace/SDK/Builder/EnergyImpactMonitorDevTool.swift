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
        List {
            Section("Power Consumption Profile") {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: viewModel.impactScore / 100)
                            .stroke(viewModel.impactScore > 60 ? Color.orange : Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(Int(viewModel.impactScore))")
                                .font(.system(size: 44, weight: .black, design: .rounded))
                            Text("IMPACT").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 140, height: 140)
                    .padding(.top, 10)

                    HStack(spacing: 20) {
                        ImpactMetric(label: "State", value: viewModel.impactScore < 30 ? "Green" : "Warning", color: viewModel.impactScore < 30 ? .green : .orange)
                        ImpactMetric(label: "Battery", value: "\(Int(UIDevice.current.batteryLevel * 100))%", color: .blue)
                    }
                }
                .padding(.vertical, 12)
            }

            Section("Usage Breakdown") {
                LabeledContent("CPU Threads", value: viewModel.cpuIntensity)
                LabeledContent("Network Throughput", value: viewModel.networkActivity)
                LabeledContent("Location Hardware", value: viewModel.locationActive ? "On" : "Idle")
                LabeledContent("Display Brightness", value: "\(Int(UIScreen.main.brightness * 100))%")
            }

            Section("Optimization Checklist") {
                VStack(alignment: .leading, spacing: 10) {
                    CheckItem(title: "Background App Refresh", status: "Enabled", isHealthy: false)
                    CheckItem(title: "Location Precision", status: "Best", isHealthy: false)
                    CheckItem(title: "Framerate Cap", status: "120 FPS", isHealthy: true)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Energy Monitor")
    }
}

struct ImpactMetric: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline.bold())
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct CheckItem: View {
    let title: String
    let status: String
    let isHealthy: Bool
    var body: some View {
        HStack {
            Image(systemName: isHealthy ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isHealthy ? .green : .orange)
            VStack(alignment: .leading) {
                Text(title).font(.caption.bold())
                Text(status).font(.system(size: 8)).foregroundStyle(.secondary)
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
