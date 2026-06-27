import SwiftUI

public struct TLANDiagnosticsView: View {
    @State private var viewModel = TLANDiagnosticsViewModel()
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        List {
            Section("Status") {
                LabeledContent("Connection", value: "Disconnected")
                LabeledContent("Protocol Ver.", value: "v1")
            }
            Section {
                Button("Export Diagnostics") {
                    viewModel.exportLogs()
                }
                Button("Reset & Unpair", role: .destructive) {
                    Task {
                        await viewModel.resetAndUnpair()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("TLAN Diagnostics")
    }
}
