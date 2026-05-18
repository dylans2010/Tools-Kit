import SwiftUI

struct CrashLogViewerDevTool: DevTool {
    let id = "crash-log-viewer"
    let name = "Crash Log Viewer"
    let category = DevToolCategory.diagnostics
    let icon = "exclamationmark.octagon.fill"
    let description = "Inspect and analyze application crash reports"

    func render() -> some View {
        CrashLogViewerView()
    }
}

struct CrashLogViewerView: View {
    @StateObject private var viewModel = CrashLogViewerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Crash Log Viewer",
                description: "Review historical crash reports and symbolicated stack traces to debug stability issues.",
                icon: "exclamationmark.octagon.fill"
            )
            .padding()

            List {
                if viewModel.crashes.isEmpty {
                    ContentUnavailableView("No Crashes", systemImage: "checkmark.circle", description: Text("Everything is running smoothly."))
                } else {
                    ForEach(viewModel.crashes) { crash in
                        NavigationLink {
                            ScrollView {
                                Text(crash.stackTrace)
                                    .font(.system(.caption2, design: .monospaced))
                                    .padding()
                            }
                            .navigationTitle("Crash Detail")
                        } label: {
                            VStack(alignment: .leading) {
                                Text(crash.reason).font(.headline).foregroundStyle(.red)
                                Text(crash.date, style: .date).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .onAppear { viewModel.load() }
    }
}

struct CrashReport: Identifiable {
    let id = UUID()
    let date: Date
    let reason: String
    let stackTrace: String
}

class CrashLogViewerViewModel: ObservableObject {
    @Published var crashes: [CrashReport] = []

    func load() {
        crashes = [
            CrashReport(date: Date().addingTimeInterval(-86400), reason: "EXC_BAD_ACCESS", stackTrace: "0   libsystem_kernel.dylib 0x1..."),
            CrashReport(date: Date().addingTimeInterval(-172800), reason: "SIGSEGV", stackTrace: "0   ToolsKit 0x2...")
        ]
    }
}
