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
        ScrollView {
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 20)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.level))
                        .stroke(viewModel.level > 0.2 ? Color.green : Color.red, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack {
                        Text("\(Int(viewModel.level * 100))%")
                            .font(.system(size: 40, weight: .bold))
                        Text(viewModel.state)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 200, height: 200)
                .padding()

                Form {
                    Section(header: Text("Power Details")) {
                        LabeledContent("Charging State", value: viewModel.state)
                        LabeledContent("Level", value: String(format: "%.0f%%", viewModel.level * 100))
                    }
                }
                .frame(height: 200) // Form in ScrollView needs height
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}

class BatteryStatusViewModel: ObservableObject {
    @Published var level: Float = 0
    @Published var state = "Unknown"
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

    private func update() {
        level = UIDevice.current.batteryLevel
        switch UIDevice.current.batteryState {
        case .unplugged: state = "Unplugged"
        case .charging: state = "Charging"
        case .full: state = "Full"
        default: state = "Unknown"
        }
    }
}

#Preview {
    BatteryStatusView()
}
