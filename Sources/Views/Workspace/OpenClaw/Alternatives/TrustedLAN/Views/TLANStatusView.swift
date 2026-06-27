import SwiftUI
public struct TLANStatusView: View {
    @State private var viewModel = TLANStatusViewModel()
    public var body: some View { List { Section("Connection") { HStack { Text("Status"); Spacer(); Text(viewModel.isConnected ? "Connected" : "Disconnected").foregroundStyle(viewModel.isConnected ? .green : .secondary) } } }.navigationTitle("TLAN Status") }
}
