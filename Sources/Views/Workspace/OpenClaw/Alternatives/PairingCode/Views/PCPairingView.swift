import SwiftUI
public struct PCPairingView: View {
    @State private var viewModel = PCPairingViewModel()
    public var body: some View { VStack { if viewModel.state == .submitting { ProgressView("Validating Code...") } }.navigationTitle("Pairing") }
}
