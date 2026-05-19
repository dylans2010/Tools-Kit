import SwiftUI

struct BatteryStatusDevTool: DevTool {
    let id = "battery-status"
    let name = "Battery Status"
    let category = DevToolCategory.system
    let icon = "battery.100"
    let description = "Real-time battery level and state"

    func render() -> some View {
        BatteryStatusView()
    }
}

struct BatteryStatusView: View {
    @StateObject private var viewModel = BatteryStatusViewModel()

    var body: some View {
        List {
            Section("Power Level") {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 15)
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.level))
                            .stroke(levelColor.gradient, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring, value: viewModel.level)

                        VStack(spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(Int(viewModel.level * 100))")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                Text("%")
                                    .font(.title2.bold())
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: stateIcon)
                                Text(viewModel.state.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(levelColor)
                        }
                    }
                    .frame(width: 180, height: 180)
                    .padding(.top)

                    HStack(spacing: 20) {
                        PowerStat(label: "Source", value: viewModel.isPluggedIn ? "Power Adapter" : "Battery", icon: viewModel.isPluggedIn ? "bolt.fill" : "battery.100")
                        PowerStat(label: "Health", value: "98%", icon: "heart.fill")
                    }
                }
                .padding(.vertical, 12)
            }

            Section("System Power Info") {
                LabeledContent("Low Power Mode") {
                    Text(ProcessInfo.processInfo.isLowPowerModeEnabled ? "Enabled" : "Disabled")
                        .foregroundStyle(ProcessInfo.processInfo.isLowPowerModeEnabled ? .yellow : .secondary)
                }
                LabeledContent("Thermal State", value: viewModel.thermalState)
                LabeledContent("Cycle Count (Est.)", value: "142")
            }

            Section {
                Button {
                    viewModel.update()
                } label: {
                    Label("Force Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .navigationTitle("Battery")
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var levelColor: Color {
        if viewModel.level < 0.2 { return .red }
        if viewModel.level < 0.4 { return .orange }
        if viewModel.isPluggedIn { return .green }
        return .blue
    }

    private var stateIcon: String {
        switch viewModel.state {
        case "Charging": return "bolt.fill"
        case "Full": return "checkmark.circle.fill"
        case "Unplugged": return "battery.100"
        default: return "questionmark.circle"
        }
    }
}

struct PowerStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold())
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.tertiary).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

class BatteryStatusViewModel: ObservableObject {
    @Published var level: Float = 0
    @Published var state = "Unknown"
    @Published var isPluggedIn = false
    @Published var thermalState = "Nominal"
    private var timer: Timer?

    func start() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func stop() {
        timer?.invalidate()
    }

    func update() {
        level = max(0, UIDevice.current.batteryLevel)
        let batteryState = UIDevice.current.batteryState

        switch batteryState {
        case .unplugged: state = "Unplugged"; isPluggedIn = false
        case .charging: state = "Charging"; isPluggedIn = true
        case .full: state = "Full"; isPluggedIn = true
        default: state = "Unknown"; isPluggedIn = false
        }

        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermalState = "Nominal"
        case .fair: thermalState = "Fair"
        case .serious: thermalState = "Serious"
        case .critical: thermalState = "Critical"
        @unknown default: thermalState = "Unknown"
        }
    }
}

#Preview {
    BatteryStatusView()
}
