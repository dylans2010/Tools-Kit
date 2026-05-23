import SwiftUI
import Darwin

struct Diag_MemoryPressureView: View {
    @State private var memoryInfo: [(String, String)] = []
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var memHistory: [(Date, UInt64)] = []

    var body: some View {
        Form {
            Section("Memory Pressure") {
                VStack(spacing: 8) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Memory Monitor")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Current Usage") {
                ForEach(memoryInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption.monospacedDigit()) }
                }
            }

            if memHistory.count > 1 {
                Section("Memory Trend") {
                    GeometryReader { geo in
                        let maxMem = memHistory.map { $0.1 }.max() ?? 1
                        Path { path in
                            let stepX = geo.size.width / CGFloat(max(memHistory.count - 1, 1))
                            for (i, reading) in memHistory.enumerated() {
                                let y = geo.size.height * (1 - CGFloat(reading.1) / CGFloat(maxMem))
                                let x = CGFloat(i) * stepX
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)
                    }
                    .frame(height: 80)
                }
            }

            Section {
                Button { isMonitoring ? stopMonitoring() : startMonitoring() } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Memory Pressure")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refresh() }
        .onDisappear { stopMonitoring() }
    }

    private func refresh() {
        var info: [(String, String)] = []
        let pi = ProcessInfo.processInfo
        let physicalMem = pi.physicalMemory
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory

        info.append(("Physical RAM", formatter.string(fromByteCount: Int64(physicalMem))))

        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            let resident = taskInfo.resident_size
            let virtual = taskInfo.virtual_size
            info.append(("App Resident", formatter.string(fromByteCount: Int64(resident))))
            info.append(("App Virtual", formatter.string(fromByteCount: Int64(virtual))))
            info.append(("Usage %", String(format: "%.1f%%", Double(resident) / Double(physicalMem) * 100)))
            memHistory.append((Date(), UInt64(resident)))
            if memHistory.count > 100 { memHistory.removeFirst() }
        }

        info.append(("Thermal", thermalStr(pi.thermalState)))
        info.append(("Low Power", pi.isLowPowerModeEnabled ? "On" : "Off"))

        memoryInfo = info
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in refresh() }
    }

    private func stopMonitoring() { timer?.invalidate(); timer = nil; isMonitoring = false }

    private func thermalStr(_ state: ProcessInfo.ThermalState) -> String {
        switch state { case .nominal: return "Nominal"; case .fair: return "Fair"; case .serious: return "Serious"; case .critical: return "Critical"; @unknown default: return "Unknown" }
    }
}
