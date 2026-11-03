import SwiftUI

struct Diag_StorageVolumeImportantView: View {
    @State private var sizeText = "—"
    @State private var freeText = "—"
    @State private var pathText = "—"
    @State private var countText = "—"

    var body: some View {
        Form {
            Section("Storage") {
                LabeledContent("Path") { Text(pathText).font(.caption) }
                LabeledContent("Size") { Text(sizeText).monospacedDigit() }
                LabeledContent("Free / Important") { Text(freeText).monospacedDigit() }
                LabeledContent("File Count") { Text(countText).monospacedDigit() }
            }
            Section { Button("Refresh") { load() } }
        }
        .navigationTitle("Volume Capacity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
        sizeText = fmt(Int64(values?.volumeTotalCapacity ?? 0))
        freeText = fmt(Int64(values?.volumeAvailableCapacityForImportantUsage ?? 0))
        pathText = NSHomeDirectory()
        countText = "—"
    }

    private func fmt(_ bytes: Int64) -> String {
        let f = ByteCountFormatter(); f.countStyle = .file; return f.string(fromByteCount: bytes)
    }
}
