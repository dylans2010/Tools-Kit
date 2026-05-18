import SwiftUI

struct RuntimeInspectorDevTool: DevTool {
    let id = "runtime-inspector"
    let name = "Runtime Inspector"
    let category = DevToolCategory.debugging
    let icon = "play.circle"
    let description = "Inspect runtime variables"

    func render() -> some View {
        RuntimeInspectorView()
    }
}

struct RuntimeInspectorView: View {
    var body: some View {
        List {
            Section("Environment") {
                LabeledContent("Simulator", value: isSimulator ? "Yes" : "No")
                LabeledContent("Debugger", value: isDebuggerAttached ? "Attached" : "None")
            }
        }
    }

    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    var isDebuggerAttached: Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let rc = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        return rc == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
    }
}
