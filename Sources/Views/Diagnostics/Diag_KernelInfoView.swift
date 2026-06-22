import SwiftUI

struct Diag_KernelInfoView: View {
    @State private var kernelVersion: String = ""
    @State private var hostname: String = ""
    @State private var osRelease: String = ""
    @State private var osType: String = ""
    @State private var machine: String = ""
    @State private var pageSize: Int = 0
    @State private var cpuType: String = ""
    @State private var cpuSubtype: String = ""
    @State private var sysctlInfo: [SysctlEntry] = []

    struct SysctlEntry: Identifiable {
        let id = UUID()
        let key: String
        let value: String
    }

    var body: some View {
        Form {
            Section("Kernel") {
                LabeledContent("Version") { Text(kernelVersion).font(.caption) }
                LabeledContent("OS Type") { Text(osType) }
                LabeledContent("OS Release") { Text(osRelease).font(.caption.monospaced()) }
                LabeledContent("Hostname") { Text(hostname) }
                LabeledContent("Machine") { Text(machine).font(.caption.monospaced()) }
            }

            Section("CPU") {
                LabeledContent("Architecture") { Text(cpuType) }
                LabeledContent("Subtype") { Text(cpuSubtype) }
                LabeledContent("Logical Cores") { Text("\(ProcessInfo.processInfo.processorCount)") }
                LabeledContent("Active Cores") { Text("\(ProcessInfo.processInfo.activeProcessorCount)") }
                LabeledContent("Physical Memory") {
                    Text(formatBytes(ProcessInfo.processInfo.physicalMemory))
                }
            }

            Section("Virtual Memory") {
                LabeledContent("Page Size") { Text("\(pageSize) bytes").monospacedDigit() }
                let vmStats = getVMStats()
                LabeledContent("Free Pages") { Text("\(vmStats.free)").monospacedDigit() }
                LabeledContent("Active Pages") { Text("\(vmStats.active)").monospacedDigit() }
                LabeledContent("Inactive Pages") { Text("\(vmStats.inactive)").monospacedDigit() }
                LabeledContent("Wired Pages") { Text("\(vmStats.wired)").monospacedDigit() }
            }

            Section("System Parameters") {
                ForEach(sysctlInfo, id: \.id) { entry in
                    LabeledContent(entry.key) {
                        Text(entry.value)
                            .font(.caption.monospaced())
                            .lineLimit(2)
                    }
                }
            }

            Section("Boot") {
                LabeledContent("System Uptime") {
                    Text(formatUptime(ProcessInfo.processInfo.systemUptime))
                        .monospacedDigit()
                }
                LabeledContent("Boot Time") {
                    let bootTime = Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)
                    Text(bootTime, style: .date)
                }
            }
        }
        .navigationTitle("Kernel Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadInfo() }
    }

    private func loadInfo() {
        var uts = utsname()
        uname(&uts)

        kernelVersion = withUnsafePointer(to: &uts.version) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }
        hostname = withUnsafePointer(to: &uts.nodename) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }
        osRelease = withUnsafePointer(to: &uts.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }
        osType = withUnsafePointer(to: &uts.sysname) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }
        machine = withUnsafePointer(to: &uts.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }

        pageSize = Int(vm_kernel_page_size)
        cpuType = getCPUType()
        cpuSubtype = getCPUSubtype()
        loadSysctl()
    }

    private func getCPUType() -> String {
        var type: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctlbyname("hw.cputype", &type, &size, nil, 0)
        switch type {
        case 12: return "ARM"
        case 12 | 0x01000000: return "ARM64"
        case 7: return "x86"
        case 7 | 0x01000000: return "x86_64"
        default: return "Unknown (\(type))"
        }
    }

    private func getCPUSubtype() -> String {
        var subtype: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctlbyname("hw.cpusubtype", &subtype, &size, nil, 0)
        return "\(subtype)"
    }

    private func loadSysctl() {
        let keys = [
            "kern.osversion",
            "kern.osproductversion",
            "hw.model",
            "hw.memsize",
            "hw.ncpu",
            "hw.physicalcpu",
            "hw.logicalcpu",
            "hw.cpufrequency_max",
            "hw.l1dcachesize",
            "hw.l1icachesize",
            "hw.l2cachesize",
        ]

        sysctlInfo = keys.compactMap { key in
            if let value = getSysctl(key) {
                return SysctlEntry(key: key.replacingOccurrences(of: "kern.", with: "").replacingOccurrences(of: "hw.", with: ""), value: value)
            }
            return nil
        }
    }

    private func getSysctl(_ name: String) -> String? {
        var size: Int = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return nil }

        if size <= MemoryLayout<Int64>.size {
            var value: Int64 = 0
            var s = MemoryLayout<Int64>.size
            if sysctlbyname(name, &value, &s, nil, 0) == 0 {
                if value > 1024 * 1024 { return formatBytes(UInt64(value)) }
                return "\(value)"
            }
        }

        var buffer = [CChar](repeating: 0, count: size)
        if sysctlbyname(name, &buffer, &size, nil, 0) == 0 {
            return String(cString: buffer)
        }
        return nil
    }

    private func getVMStats() -> (free: UInt64, active: UInt64, inactive: UInt64, wired: UInt64) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0, 0, 0) }
        return (UInt64(stats.free_count), UInt64(stats.active_count), UInt64(stats.inactive_count), UInt64(stats.wire_count))
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        if d > 0 { return "\(d)d \(h)h \(m)m" }
        return "\(h)h \(m)m"
    }
}
