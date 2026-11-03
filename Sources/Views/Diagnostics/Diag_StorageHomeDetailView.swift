import SwiftUI

struct Diag_StorageHomeDetailView: View {
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
        .navigationTitle("Home Storage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        sizeText = fmt((attrs?[.systemSize] as? Int64) ?? 0)
        freeText = fmt((attrs?[.systemFreeSize] as? Int64) ?? 0)
        pathText = NSHomeDirectory()
        countText = "— (filesystem attributes, not an enumeration)"
    }

    private func fmt(_ bytes: Int64) -> String {
        let f = ByteCountFormatter(); f.countStyle = .file; return f.string(fromByteCount: bytes)
    }
}
