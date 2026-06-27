import SwiftUI
public struct PCCodeEntryView: View {
    @State private var viewModel = PCCodeEntryViewModel(); @State private var pairingVM = PCPairingViewModel()
    public var body: some View {
        VStack(spacing: 30) { Text("Enter the 8-digit code shown on your Mac").font(.headline); TextField("00000000", text: $viewModel.code).font(.system(size: 40, weight: .bold, design: .monospaced)).keyboardType(.numberPad).multilineTextAlignment(.center).padding()
            Button("Pair") { Task { await pairingVM.submitCode(viewModel.code, host: "localhost", port: 9876) } }.buttonStyle(.borderedProminent).disabled(!viewModel.isValid)
            if pairingVM.state == .submitting { ProgressView() }
        }.padding().navigationTitle("Enter Code")
    }
}
