import SwiftUI

struct Diag_MemoryMapView: View {
    var body: some View {
        List {
            Section("Process Memory Regions") {
                MemoryRegionRow(name: "__TEXT (Code)", size: "450 MB", protection: "r-x")
                MemoryRegionRow(name: "__DATA (Data)", size: "120 MB", protection: "rw-")
                MemoryRegionRow(name: "Malloc Heap", size: "1.2 GB", protection: "rw-")
                MemoryRegionRow(name: "Stack", size: "8 MB", protection: "rw-")
            }
        }
        .navigationTitle("Memory Mapping")
    }
}

struct MemoryRegionRow: View {
    let name: String
    let size: String
    let protection: String
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.subheadline)
                Text(protection)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(size)
                .font(.body.monospacedDigit())
        }
    }
}
