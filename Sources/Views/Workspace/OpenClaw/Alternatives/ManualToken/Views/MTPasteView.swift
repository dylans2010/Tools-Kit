import SwiftUI
public struct MTPasteView: View {
    @State private var viewModel = MTPasteViewModel(); @State private var pairingVM = MTPairingViewModel()
    public var body: some View { VStack { TextField("Token", text: $viewModel.token); Button("Validate") { Task { await pairingVM.pair(token: viewModel.token, host: "localhost", port: 9876) } } } }
}
