
import SwiftUI

struct ConnectorBinaryDataView: View {
    @State private var allowLargeUploads = false
    @State private var maxUploadSizeMB: Double = 10
    @State private var streamingEnabled = false

    var body: some View {
        Form {
            Section("Binary Handling") {
                Toggle("Support Binary Payloads", isOn: $allowLargeUploads)
                if allowLargeUploads {
                    VStack(alignment: .leading) {
                        Text("Max Upload Size: \(Int(maxUploadSizeMB)) MB")
                        Slider(value: $maxUploadSizeMB, in: 1...100, step: 5)
                    }
                }
            }

            Section("Streaming") {
                Toggle("Enable Request Streaming", isOn: $streamingEnabled)
                Text("Required for handling very large files or real-time data streams.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Binary Data")
    }
}
