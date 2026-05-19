import SwiftUI

struct AppStateInspectorDevTool: DevTool {
    let id = "app-state-inspector"
    let name = "App State Inspector"
    let category = DevToolCategory.diagnostics
    let icon = "info.circle"
    let description = "Monitor application lifecycle states"

    func render() -> some View {
        AppStateInspectorView()
    }
}

struct AppStateInspectorView: View {
    @StateObject private var viewModel = AppStateInspectorViewModel()

    var body: some View {
        Form {
            Section("Current State") {
                HStack {
                    Text(viewModel.currentState)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))
                    Spacer()
                    Text("Active for \(viewModel.uptime)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Lifecycle History") {
                ForEach(viewModel.history) { item in
                    HStack {
                        Text(item.title).font(.subheadline)
                        Spacer()
                        Text(item.timestamp, style: .time).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

class AppStateInspectorViewModel: ObservableObject {
    @Published var currentState = "Active"
    @Published var uptime = "05:22"
    @Published var history: [HistoryItem] = [
        HistoryItem(title: "Will Enter Foreground", detail: ""),
        HistoryItem(title: "Did Become Active", detail: "")
    ]
}

#Preview {
    AppStateInspectorView()
}
