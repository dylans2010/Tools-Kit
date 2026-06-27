import SwiftUI
public struct TLANHomeView: View {
    @State private var discoveryVM = TLANDiscoveryViewModel()
    public init() {}
    public var body: some View {
        List {
            Section("Method") { Text("Trusted LAN Pairing").font(.headline); Text("Automatically find your Mac and request permission to connect.").font(.subheadline).foregroundStyle(.secondary) }
            Section("Status") { HStack { Text("Paired Status"); Spacer(); Text("Not Paired").foregroundStyle(.secondary) } }
            Section { NavigationLink("Start Discovery") { TLANDiscoveryView(viewModel: discoveryVM) } }
            Section { NavigationLink("User Guide") { TLANGuideView() } }
        }.navigationTitle("Trusted LAN")
    }
}
