import SwiftUI


struct Diag_SystemDeviceIdentityView: View {
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
        .navigationTitle("Device Identity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Marketing Name", DeviceModelCatalog.marketingName(for: DeviceModelCatalog.currentIdentifier())),
            ("Model Identifier", DeviceModelCatalog.currentIdentifier()),
            ("Model", UIDevice.current.model),
            ("Vendor ID", UIDevice.current.identifierForVendor?.uuidString ?? "Unavailable"),
            ("Catalog Status", DeviceModelCatalog.currentInfo().isProvisional ? "Provisional" : "Confirmed")
        ]
    }
}
