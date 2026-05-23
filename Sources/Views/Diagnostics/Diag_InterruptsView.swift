import SwiftUI

struct Diag_InterruptsView: View {
    var body: some View {
        List {
            Section("CPU Interrupts") {
                VStack(spacing: 12) {
                    InterruptRow(label: "Hardware Interrupts", value: "1,240/s", trend: "up")
                    InterruptRow(label: "Software Interrupts", value: "840/s", trend: "down")
                    InterruptRow(label: "Context Switches", value: "4,500/s", trend: "stable")
                }
            }

            Section("I/O Events") {
                LabeledContent("Disk I/O", value: "12 ops/s")
                LabeledContent("Network I/O", value: "142 pkts/s")
            }

            Section(footer: Text("High interrupt rates can indicate hardware issues or heavy background activity.")) {
                EmptyView()
            }
        }
        .navigationTitle("System Interrupts")
    }
}

struct InterruptRow: View {
    let label: String
    let value: String
    let trend: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .monospacedDigit()
            Image(systemName: trendIcon)
                .foregroundStyle(trendColor)
        }
    }

    private var trendIcon: String {
        switch trend {
        case "up": return "arrow.up.right"
        case "down": return "arrow.down.right"
        default: return "arrow.right"
        }
    }

    private var trendColor: Color {
        switch trend {
        case "up": return .red
        case "down": return .green
        default: return .gray
        }
    }
}
