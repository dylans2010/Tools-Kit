import SwiftUI

public struct DiagnosticsCenterView: View {
    @StateObject private var viewModel = DiagnosticsViewModel()

    public init() {}

    public body: some View {
        List {
            Section("Device & OS") {
                if let diagnostics = viewModel.diagnostics {
                    InfoRow(label: "Model", value: diagnostics.deviceName)
                    InfoRow(label: "OS Version", value: diagnostics.osVersion)
                    InfoRow(label: "App Version", value: diagnostics.appVersion)
                    InfoRow(label: "Build", value: diagnostics.buildNumber)
                }
            }

            Section("System Performance") {
                if let diagnostics = viewModel.diagnostics {
                    InfoRow(label: "Memory Usage", value: diagnostics.memoryUsage)
                    InfoRow(label: "CPU Usage", value: diagnostics.cpuUsage)
                    InfoRow(label: "Network", value: diagnostics.networkStatus)
                }
            }

            Section("Recent Logs") {
                if let diagnostics = viewModel.diagnostics {
                    ForEach(diagnostics.logs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption2, design: .monospaced))
                    }
                }
            }

            Section {
                Button("Capture Fresh Snapshot") {
                    Task {
                        await viewModel.capture()
                    }
                }
                .disabled(viewModel.isCapturing)
            }
        }
        .navigationTitle("Diagnostics")
        .task {
            await viewModel.capture()
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(.secondary).bold()
        }
    }
}
