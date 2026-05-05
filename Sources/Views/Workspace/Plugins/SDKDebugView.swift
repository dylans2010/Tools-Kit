import SwiftUI

struct SDKDebugView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @State private var isStepping = false

    var body: some View {
        List {
            Section("Runtime Status") {
                HStack {
                    Text("Execution Mode")
                    Spacer()
                    Text(runtime.isNoSandboxModeEnabled ? "Unrestricted" : "Sandboxed")
                        .foregroundStyle(runtime.isNoSandboxModeEnabled ? .red : .green)
                }
                HStack {
                    Text("Active Projects")
                    Spacer()
                    Text("\(runtime.activeProjects.count)")
                }
            }

            Section("Memory inspection (Real)") {
                HStack {
                    Text("Process Memory")
                    Spacer()
                    Text("\(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB")
                        .font(.system(.body, design: .monospaced))
                }
            }

            Section("Thread Trace") {
                ForEach(Thread.callStackSymbols.prefix(5), id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 8, design: .monospaced))
                        .lineLimit(1)
                }
            }

            Section {
                Button(isStepping ? "Stop Debug" : "Start Trace") {
                    isStepping.toggle()
                }
                .foregroundStyle(isStepping ? .red : .blue)
            }
        }
        .navigationTitle("SDK Runtime Debug")
    }
}
