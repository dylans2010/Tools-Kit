import SwiftUI

struct BreakpointManagerDevTool: DevTool {
    let id = "breakpoint-manager"
    let name = "Breakpoint Manager"
    let category = DevToolCategory.debugging
    let icon = "pause.fill"
    let description = "Manage runtime breakpoints"

    func render() -> some View {
        BreakpointManagerView()
    }
}

struct BreakpointManagerView: View {
    @State private var breakpoints = [
        "SDKBuildView.swift:150",
        "NetworkReachability.swift:45"
    ]

    var body: some View {
        List {
            Section("Active Breakpoints") {
                ForEach(breakpoints, id: \.self) { bp in
                    HStack {
                        Image(systemName: "circle.fill").foregroundStyle(.blue)
                        Text(bp)
                    }
                }
                .onDelete { breakpoints.remove(atOffsets: $0) }
            }
        }
    }
}
