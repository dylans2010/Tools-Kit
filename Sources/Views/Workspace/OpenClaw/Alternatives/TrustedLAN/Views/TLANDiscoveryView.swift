import SwiftUI
import Network
public struct TLANDiscoveryView: View {
    @Bindable var viewModel: TLANDiscoveryViewModel
    public var body: some View {
        List {
            if viewModel.results.isEmpty { Section { HStack { ProgressView(); Text("Searching for Gateways...").padding(.leading, 8) } } }
            else { Section("Discovered Devices") { ForEach(viewModel.results, id: \.self) { r in
                NavigationLink(destination: TLANPairingView(result: r)) { VStack(alignment: .leading) { Text(r.endpoint.debugDescription).font(.headline); Text("Select to request pairing").font(.caption).foregroundStyle(.secondary) } }
            } } }
        }.navigationTitle("Discovery").task { await viewModel.startDiscovery() }.onDisappear { Task { await viewModel.stopDiscovery() } }
    }
}
