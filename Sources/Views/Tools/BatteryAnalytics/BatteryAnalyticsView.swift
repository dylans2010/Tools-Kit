import SwiftUI

struct BatteryAnalyticsView: View {
    @StateObject private var backend = BatteryAnalyticsBackend()

    var body: some View {
        ToolDetailView(tool: BatteryAnalyticsTool()) {
            VStack(spacing: 24) {
                // Battery Visual
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 4)
                        .frame(width: 200, height: 100)

                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(batteryColor)
                            .frame(width: CGFloat(max(0, backend.batteryLevel)) * 192, height: 92)
                        Spacer(minLength: 0)
                    }
                    .frame(width: 192, height: 92)

                    Text("\(Int(backend.batteryLevel * 100))%")
                        .font(.title.bold())
                }
                .overlay(
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 10, height: 40)
                        .cornerRadius(4)
                        .offset(x: 108),
                    alignment: .center
                )

                ToolInputSection("Status") {
                    HStack {
                        Text("Charging State")
                        Spacer()
                        Text(stateString)
                            .bold()
                    }
                    .padding()

                    Divider()

                    HStack {
                        Text("Low Power Mode")
                        Spacer()
                        Text(backend.isLowPowerMode ? "Enabled" : "Disabled")
                            .foregroundColor(backend.isLowPowerMode ? .orange : .secondary)
                    }
                    .padding()
                }
            }
        }
        .onAppear { backend.refresh() }
    }

    private var batteryColor: Color {
        if backend.batteryLevel <= 0.2 { return .red }
        if backend.batteryLevel <= 0.5 { return .yellow }
        return .green
    }

    private var stateString: String {
        switch backend.batteryState {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "On Battery"
        default: return "Unknown"
        }
    }
}

struct BatteryAnalyticsTool: Tool, Sendable {
    let name = "Battery Analytics"
    let icon = "battery.100"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Real-time battery health and usage analytics"
    let requiresAPI = false
    var view: AnyView { AnyView(BatteryAnalyticsView()) }
}
