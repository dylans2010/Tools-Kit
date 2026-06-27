import SwiftUI
public struct PCDiagnosticsView: View {
    @State private var viewModel = PCDiagnosticsViewModel()
    public var body: some View { List { Section("Stats") { LabeledContent("Attempts", value: "\(viewModel.attemptCount)") } }.navigationTitle("PC Diagnostics") }
}
