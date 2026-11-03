import SwiftUI

struct Diag_StorageTmpDetailView: View {
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
        .navigationTitle("Temporary Storage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        guard let dir = FileManager.default.temporaryDirectory else { return }
        pathText = dir.path
        var total: Int64 = 0
        var count = 0
        if let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                count += 1
                if let v = try? fileURL.resourceValues(forKeys: [.fileSizeKey]), let s = v.fileSize { total += Int64(s) }
            }
        }
        sizeText = fmt(total)
        freeText = "—"
        countText = "\(count)"
    }

    private func fmt(_ bytes: Int64) -> String {
        let f = ByteCountFormatter(); f.countStyle = .file; return f.string(fromByteCount: bytes)
    }
}
