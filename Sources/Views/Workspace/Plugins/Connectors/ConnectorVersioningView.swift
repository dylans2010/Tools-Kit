import SwiftUI

struct ConnectorVersioningView: View {
    let connector: ConnectorDefinition

    var body: some View {
        List {
            Section("Current Version") {
                HStack {
                    Text("v\(connector.version)").font(.headline)
                    Spacer()
                    Text("Active").foregroundColor(.green).font(.caption.bold())
                }
            }

            Section("History") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("v1.0.0").font(.subheadline.bold())
                    Text("Initial release").font(.caption).secondary()
                    Text(Date().formatted()).font(.system(size: 10)).secondary()
                }
            }

            Section {
                Button("Create New Release") {
                    // Logic to increment version
                }
            }
        }
        .navigationTitle("Versioning")
    }
}
