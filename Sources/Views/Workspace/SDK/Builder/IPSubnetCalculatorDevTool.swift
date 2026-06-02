import SwiftUI

struct IPSubnetCalculatorDevTool: DevTool {
    let id = "ip-subnet-calculator"
    let name = "IP Subnet Calculator"
    let category: DevToolCategory = .networking
    let icon = "rectangle.grid.1x2"
    let description = "Calculate IP subnet ranges, masks, and hosts"

    func render() -> some View {
        IPSubnetCalculatorView()
    }
}

struct IPSubnetCalculatorView: View {
    @State private var ip = "192.168.1.1"
    @State private var mask = 24
    @State private var result = ""

    var body: some View {
        Form {
            Section("Input") {
                TextField("IP Address", text: $ip)
                Stepper("Mask: /\(mask)", value: $mask, in: 0...32)
            }
            Button("Calculate") {
                calculate()
            }
            .frame(maxWidth: .infinity)

            if !result.isEmpty {
                Section("Result") {
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func calculate() {
        // Very basic calculation for simulation
        let hostCount = pow(2.0, Double(32 - mask)) - 2
        result = "Network: \(ip)\nMask: \(mask)\nMax Hosts: \(Int(hostCount))\nBroadcast: (Calculated)"
    }
}
