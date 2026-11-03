import SwiftUI

/// Real app memory from task_info. The previous version hardcoded
/// "__TEXT 450 MB / __DATA 120 MB / Malloc Heap 1.2 GB / Stack 8 MB" —
/// a per-region map is not exposed to App Store apps, so those numbers
/// were invented. This version reports this process's real resident and
/// virtual sizes, physical memory, and thread count from mach APIs.
struct Diag_MemoryMapView: View {
    @State private var rows: [(String, String)] = []

    var body: some View {
        List {
            Section("Process Memory Regions") {
                if rows.isEmpty {
                    Text("Memory info unavailable.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rows, id: \.0) { row in
                        MemoryRegionRow(name: row.0, size: row.1, protection: "measured")
                    }
                }
            }
            Section {
                Text("A segment-by-segment map (__TEXT / __DATA / heap / stack sizes) is not available to apps on iOS, so this tool reports the process totals that task_info actually provides instead of inventing a breakdown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                Button("Refresh") { load() }
            }
        }
        .navigationTitle("Memory Mapping")
        .onAppear { load() }
    }

    private func load() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        var threadCount: UInt32 = 0
        var threadList: thread_act_array_t?
        var threadCountOut: mach_msg_type_number_t = 0
        if task_threads(mach_task_self_, &threadList, &threadCountOut) == KERN_SUCCESS {
            threadCount = UInt32(threadCountOut)
            if let list = threadList {
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: list), vm_size_t(threadCountOut) * vm_size_t(MemoryLayout<thread_t>.stride))
            }
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        if result == KERN_SUCCESS {
            rows = [
                ("Resident Memory", formatter.string(fromByteCount: Int64(info.resident_size))),
                ("Virtual Memory", formatter.string(fromByteCount: Int64(info.virtual_size))),
                ("Physical Memory (device)", formatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory))),
                ("Threads", "\(threadCount)"),
            ]
        } else {
            rows = [
                ("Physical Memory (device)", formatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory))),
                ("Threads", "\(threadCount)"),
            ]
        }
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
