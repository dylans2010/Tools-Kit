import SwiftUI

struct BreakpointManagerDevTool: DevTool {
    let id = "breakpoint-manager"
    let name = "Breakpoint Manager"
    let category = DevToolCategory.debugging
    let icon = "pause.fill"
    let description = "Manage and toggle application breakpoints"

    func render() -> some View {
        BreakpointManagerView()
    }
}

struct BreakpointManagerView: View {
    @StateObject private var viewModel = BreakpointManagerViewModel()

    var body: some View {
        List {
            Section("Active Breakpoints") {
                if viewModel.breakpoints.isEmpty {
                    Text("No breakpoints defined").foregroundStyle(.secondary)
                } else {
                    ForEach($viewModel.breakpoints) { $bp in
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(bp.isActive ? .red : .secondary)
                            VStack(alignment: .leading) {
                                Text(bp.location).font(.subheadline.bold())
                                Text(bp.condition).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $bp.isActive).labelsHidden()
                        }
                    }
                }
            }
        }
    }
}

struct Breakpoint: Identifiable {
    let id = UUID()
    var location: String
    var condition: String
    var isActive: Bool
}

class BreakpointManagerViewModel: ObservableObject {
    @Published var breakpoints: [Breakpoint] = [
        Breakpoint(location: "ToolsKitSDK.swift:150", condition: "scope == .notes", isActive: true),
        Breakpoint(location: "SDKDataEngine.swift:42", condition: "None", isActive: false)
    ]
}

#Preview {
    BreakpointManagerView()
}
