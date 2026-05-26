import SwiftUI

struct Diag_CPUTopologyView: View {
    let processorCount = ProcessInfo.processInfo.processorCount
    let activeProcessorCount = ProcessInfo.processInfo.activeProcessorCount

    var body: some View {
        List {
            Section("Processor Layout") {
                LabeledContent("Physical Cores", value: "\(processorCount)")
                LabeledContent("Active Cores", value: "\(activeProcessorCount)")
                LabeledContent("Architecture", value: "arm64")
            }

            Section("Cluster Distribution (Estimated)") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Performance Cores")
                        Spacer()
                        Text("Active")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    }
                    ProgressView(value: 0.65)
                        .tint(.red)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Efficiency Cores")
                        Spacer()
                        Text("Power Save")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                    ProgressView(value: 0.22)
                        .tint(.green)
                }
            }
        }
        .navigationTitle("CPU Topology")
    }
}
