import SwiftUI
public struct TLANDeviceListView: View {
    @State private var viewModel = TLANDeviceListViewModel()
    public var body: some View {
        List { Section("Trusted Devices") { if viewModel.devices.isEmpty { Text("No trusted devices").foregroundStyle(.secondary) }
            else { ForEach(viewModel.devices) { d in VStack(alignment: .leading) { Text(d.name).font(.headline); Text("Paired at: \(d.pairedAt.formatted())").font(.caption) } } } }
        }.navigationTitle("Devices")
    }
}
