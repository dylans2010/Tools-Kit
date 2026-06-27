import SwiftUI
public struct TLANDiagnosticsView: View {
    public var body: some View {
        List {
            Section("Status") {
                LabeledContent("Pairing State", value: "Idle")
                LabeledContent("Connection", value: "Disconnected")
                LabeledContent("Gateway Address", value: "--")
                LabeledContent("Protocol Ver.", value: "v1")
            }
        }.navigationTitle("Diagnostics")
    }
}
