import SwiftUI
import Metal

/// Real Metal device capabilities. The previous version hardcoded
/// "Apple Family 9 / 4 GB / 16384" for every device; every value below
/// is read from MTLCreateSystemDefaultDevice() on this device.
struct Diag_MetalCapabilityView: View {
    @State private var rows: [(String, String)] = []
    @State private var families: [(String, Bool)] = []

    var body: some View {
        List {
            Section("Metal GPU Details") {
                if rows.isEmpty {
                    Text("No Metal device found on this device.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rows, id: \.0) { row in
                        LabeledContent(row.0) { Text(row.1).font(.caption.monospaced()) }
                    }
                }
            }

            Section("Feature Support") {
                ForEach(families, id: \.0) { family in
                    FeatureRow(name: family.0, supported: family.1)
                }
            }

            Section {
                Button("Refresh") { load() }
            }
        }
        .navigationTitle("Metal Capabilities")
        .onAppear { load() }
    }

    private func load() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            rows = []
            families = []
            return
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        rows = [
            ("GPU Name", device.name),
            ("Max Buffer Length", formatter.string(fromByteCount: Int64(device.maxBufferLength))),
            ("Max Threadgroup Memory", formatter.string(fromByteCount: Int64(device.maxThreadgroupMemoryLength))),
            ("Read-Write Texture Tier", "\(device.readWriteTextureSupport.rawValue)"),
            ("Argument Buffers Tier", "\(device.argumentBuffersSupport.rawValue)"),
            ("32-bit Float Filtering", device.supports32BitFloatFiltering ? "Yes" : "No"),
            ("32-bit MSAA", device.supports32BitMSAA ? "Yes" : "No"),
            ("Ray Tracing", device.supportsRaytracing ? "Yes" : "No"),
        ]
        families = [
            ("GPU Family Apple 1", device.supportsFamily(.apple1)),
            ("GPU Family Apple 2", device.supportsFamily(.apple2)),
            ("GPU Family Apple 3", device.supportsFamily(.apple3)),
            ("GPU Family Apple 4", device.supportsFamily(.apple4)),
            ("GPU Family Apple 5", device.supportsFamily(.apple5)),
            ("GPU Family Apple 6", device.supportsFamily(.apple6)),
            ("GPU Family Apple 7", device.supportsFamily(.apple7)),
            ("Mesh Shaders", device.supportsFamily(.apple7)),
        ]
    }
}

struct FeatureRow: View {
    let name: String
    let supported: Bool
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(supported ? .green : .red)
        }
    }
}
