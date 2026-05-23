import SwiftUI
import Metal

struct Diag_GPUInfoView: View {
    @State private var gpuName: String = "Unknown"
    @State private var maxThreadsPerGroup: Int = 0
    @State private var maxBufferLength: Int = 0
    @State private var recommendedMaxMemory: UInt64 = 0
    @State private var supportsRaytracing = false
    @State private var supportsMetal = false
    @State private var gpuFamily: String = "Unknown"

    var body: some View {
        Form {
            Section("GPU") {
                VStack(spacing: 12) {
                    Image(systemName: "gpu")
                        .font(.system(size: 44))
                        .foregroundStyle(.purple)
                    Text(gpuName)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Capabilities") {
                LabeledContent("Metal Support") {
                    Text(supportsMetal ? "Yes" : "No")
                        .foregroundStyle(supportsMetal ? .green : .red)
                }
                LabeledContent("GPU Family") { Text(gpuFamily) }
                LabeledContent("Ray Tracing") {
                    Text(supportsRaytracing ? "Supported" : "Not Supported")
                        .foregroundStyle(supportsRaytracing ? .green : .secondary)
                }
            }

            Section("Limits") {
                LabeledContent("Max Threads/Group") {
                    Text("\(maxThreadsPerGroup)").monospacedDigit()
                }
                LabeledContent("Max Buffer Length") {
                    Text(formattedBytes(UInt64(maxBufferLength))).monospacedDigit()
                }
                LabeledContent("Recommended Max Memory") {
                    Text(formattedBytes(recommendedMaxMemory)).monospacedDigit()
                }
            }
        }
        .navigationTitle("GPU Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadGPUInfo() }
    }

    private func loadGPUInfo() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            supportsMetal = false
            return
        }
        supportsMetal = true
        gpuName = device.name
        maxThreadsPerGroup = device.maxThreadsPerThreadgroup.width
        maxBufferLength = device.maxBufferLength
        recommendedMaxMemory = device.recommendedMaxWorkingSetSize
        supportsRaytracing = device.supportsRaytracing

        if device.supportsFamily(.apple7) {
            gpuFamily = "Apple GPU Family 7+"
        } else if device.supportsFamily(.apple6) {
            gpuFamily = "Apple GPU Family 6"
        } else if device.supportsFamily(.apple5) {
            gpuFamily = "Apple GPU Family 5"
        } else {
            gpuFamily = "Apple GPU Family 4 or earlier"
        }
    }

    private func formattedBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
