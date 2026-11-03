import SwiftUI


struct Diag_SystemModelCatalogView: View {
    @State private var rows: [(String, String)] = []

    var body: some View {
        Form {
            Section("Results") {
                ForEach(rows, id: \.0) { row in
                    LabeledContent(row.0) { Text(row.1).font(.caption) }
                }
            }

            Section {
                Button { load() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") }
                }
            }
        }
        .navigationTitle("System Model Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Current Model", DeviceModelCatalog.currentInfo().marketingName),
            ("Current Identifier", DeviceModelCatalog.currentIdentifier()),
            ("Current Dynamic Island", DeviceModelCatalog.currentInfo().hasDynamicIsland ? "Present" : "Not present"),
            ("Catalog Models", "\(DeviceModelCatalog.all.count)"),
            ("Supported Lineup", DeviceModelCatalog.supportedLineup.map { $0.marketingName }.joined(separator: ", "))
        ]
    }
}
