import SwiftUI

struct BreakpointManagerTool: DevTool {
    let id = UUID()
    let name = "Breakpoint Manager"
    let category: DevToolCategory = .debugging
    let icon = "stop.circle"
    let description = "Manage symbolic and conditional breakpoints"
    func render() -> some View { BreakpointManagerDevToolView() }
}

struct BreakpointManagerDevToolView: View {
    @State private var breakpoints: [BreakpointEntry] = []
    @State private var newSymbol = ""
    @State private var newCondition = ""

    struct BreakpointEntry: Identifiable {
        let id = UUID()
        var symbol: String
        var condition: String
        var isEnabled: Bool
        var hitCount: Int
    }

    var body: some View {
        Form {
            Section("Add Breakpoint") {
                TextField("Symbol (e.g. viewDidLoad)", text: $newSymbol)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                TextField("Condition (optional)", text: $newCondition)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                Button("Add") {
                    breakpoints.append(BreakpointEntry(
                        symbol: newSymbol, condition: newCondition,
                        isEnabled: true, hitCount: 0
                    ))
                    newSymbol = ""; newCondition = ""
                }
                .disabled(newSymbol.isEmpty)
            }
            Section("Active Breakpoints (\(breakpoints.filter(\.isEnabled).count)/\(breakpoints.count))") {
                ForEach($breakpoints) { $bp in
                    HStack {
                        Image(systemName: bp.isEnabled ? "circle.fill" : "circle")
                            .foregroundStyle(bp.isEnabled ? .blue : .secondary)
                            .onTapGesture { bp.isEnabled.toggle() }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bp.symbol).font(.system(.subheadline, design: .monospaced))
                            if !bp.condition.isEmpty {
                                Text("if \(bp.condition)")
                                    .font(.caption2).foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                        Text("\(bp.hitCount)x").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { indices in breakpoints.remove(atOffsets: indices) }
            }
            Section("Quick Actions") {
                Button("Enable All") { for i in breakpoints.indices { breakpoints[i].isEnabled = true } }
                Button("Disable All") { for i in breakpoints.indices { breakpoints[i].isEnabled = false } }
                Button("Remove All", role: .destructive) { breakpoints.removeAll() }
            }
        }
        .navigationTitle("Breakpoint Manager")
    }
}
