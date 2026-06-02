import SwiftUI

struct NetworkSpeedSimulatorDevTool: DevTool {
    let id = "network-speed-sim"
    let name = "Network Speed Simulator"
    let category: DevToolCategory = .diagnostics
    let icon = "gauge"
    let description = "Simulate different network conditions (3G, 4G, DSL)"

    func render() -> some View {
        List {
            Text("3G (750 kbps)")
            Text("4G (10 Mbps)")
            Text("Fiber (1 Gbps)")
        }
    }
}
