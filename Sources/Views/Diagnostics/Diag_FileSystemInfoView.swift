import SwiftUI

struct Diag_FileSystemInfoView: View {
    @State private var attributes: [String: String] = [:]

    var body: some View {
        Form {
            Section("File System Attributes") {
                if attributes.isEmpty {
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(attributes.keys.sorted()), id: \.self) { key in
                        LabeledContent(key) {
                            Text(attributes[key] ?? "—")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Key Directories") {
                LabeledContent("Home") {
                    Text(NSHomeDirectory())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Documents") {
                    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "—"
                    Text(docs)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Caches") {
                    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.path ?? "—"
                    Text(caches)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Temp") {
                    Text(NSTemporaryDirectory())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("File System Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadAttributes() }
    }

    private func loadAttributes() {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) else { return }
        var result: [String: String] = [:]
        for (key, value) in attrs {
            if let num = value as? NSNumber {
                if key == .systemSize || key == .systemFreeSize {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    result[key.rawValue] = formatter.string(fromByteCount: num.int64Value)
                } else {
                    result[key.rawValue] = num.stringValue
                }
            } else {
                result[key.rawValue] = "\(value)"
            }
        }
        attributes = result
    }
}
