
import SwiftUI

struct ConnectorRegionConfigView: View {
    @State private var regions: [ConnectorRegion] = [
        ConnectorRegion(name: "US East", endpoint: "us-east.api.example.com", isDefault: true),
        ConnectorRegion(name: "EU West", endpoint: "eu-west.api.example.com", isDefault: false)
    ]

    struct ConnectorRegion: Identifiable {
        let id = UUID()
        var name: String
        var endpoint: String
        var isDefault: Bool
    }

    var body: some View {
        List {
            Section("Available Regions") {
                ForEach(regions) { region in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(region.name).bold()
                            Text(region.endpoint).font(.caption2).monospaced()
                        }
                        Spacer()
                        if region.isDefault {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                    }
                }
            }

            Button("Add Region", systemImage: "plus") { }
        }
        .navigationTitle("Multi-region Config")
    }
}
