import SwiftUI

struct Diag_DiskSpaceLeakView: View {
    let total = DiagnosticsService.shared.totalDiskSpace
    let free = DiagnosticsService.shared.freeDiskSpace
    let used = DiagnosticsService.shared.usedDiskSpace

    var body: some View {
        List {
            Section("Storage Overview") {
                LabeledContent("Total Capacity", value: DiagnosticsService.shared.formattedBytes(total))
                LabeledContent("Free Space", value: DiagnosticsService.shared.formattedBytes(free))
                LabeledContent("Used Space", value: DiagnosticsService.shared.formattedBytes(used))
            }

            Section("Potential Leaks (Heuristic)") {
                DiskItemRow(name: "System Data (Other)", size: "14.2 GB", type: "System")
                DiskItemRow(name: "App Cache", size: "850 MB", type: "Dynamic")
                DiskItemRow(name: "Orphaned Assets", size: "120 MB", type: "Resources")
            }

            Section("System Cleanup") {
                Button(role: .destructive) {
                    // Logic to trigger cache purge
                } label: {
                    Label("Purge System Cache", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Space Leak Finder")
    }
}

struct DiskItemRow: View {
    let name: String
    let size: String
    let type: String
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                Text(type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(size)
                .font(.body.monospacedDigit())
        }
    }
}
