import SwiftUI
public struct TLANDiagnosticsView: View {
    @State private var viewModel = TLANDiagnosticsViewModel(); @Environment(\.dismiss) private var dismiss
    public var body: some View {
        List { Section("Status") { LabeledContent("Pairing State", value: "\(TLANPairingState.idle)"); LabeledContent("Connection", value: "Disconnected"); LabeledContent("Gateway Address", value: "--"); LabeledContent("Protocol Ver.", value: "v1") }
            Section { Button("Export Diagnostics") { viewModel.exportLogs() }; Button("Reset & Unpair", role: .destructive) {} }
        }.navigationTitle("TLAN Diagnostics")
    }
}
