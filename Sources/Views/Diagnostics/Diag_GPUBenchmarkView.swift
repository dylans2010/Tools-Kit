import SwiftUI
import Metal

struct Diag_GPUBenchmarkView: View {
    @State private var gpuInfo: [(String, String)] = []
    @State private var benchmarkScore: Int = 0
    @State private var isRunning = false
    @State private var hasRun = false

    var body: some View {
        Form {
            Section("GPU Benchmark") {
                VStack(spacing: 12) {
                    Image(systemName: "gpu")
                        .font(.system(size: 52))
                        .foregroundStyle(.purple)
                    if hasRun {
                        Text("\(benchmarkScore)")
                            .font(.system(size: 36, weight: .bold).monospacedDigit())
                            .foregroundStyle(.purple)
                        Text("GPU Score")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("GPU Hardware") {
                ForEach(gpuInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption) }
                }
            }

            Section {
                Button {
                    runGPUBenchmark()
                } label: {
                    HStack {
                        if isRunning { ProgressView().scaleEffect(0.8) }
                        else { Image(systemName: "play.circle.fill") }
                        Text(isRunning ? "Running..." : hasRun ? "Run Again" : "Start GPU Benchmark")
                    }
                }
                .disabled(isRunning)
            }
        }
        .navigationTitle("GPU Benchmark")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadGPUInfo() }
    }

    private func loadGPUInfo() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            gpuInfo = [("Metal", "Not available")]
            return
        }

        var info: [(String, String)] = []
        info.append(("GPU Name", device.name))
        info.append(("Unified Memory", device.hasUnifiedMemory ? "Yes" : "No"))
        info.append(("Max Thread Width", "\(device.maxThreadsPerThreadgroup.width)"))
        info.append(("Max Thread Height", "\(device.maxThreadsPerThreadgroup.height)"))
        info.append(("Max Thread Depth", "\(device.maxThreadsPerThreadgroup.depth)"))
        info.append(("Max Buffer Length", ByteCountFormatter.string(fromByteCount: Int64(device.maxBufferLength), countStyle: .memory)))
        info.append(("Recommended Working Set", ByteCountFormatter.string(fromByteCount: Int64(device.recommendedMaxWorkingSetSize), countStyle: .memory)))
        info.append(("Read-Write Texture Tier", "\(device.readWriteTextureSupport.rawValue)"))
        info.append(("Argument Buffers Tier", "\(device.argumentBuffersSupport.rawValue)"))

        gpuInfo = info
    }

    private func runGPUBenchmark() {
        isRunning = true

        DispatchQueue.global(qos: .userInitiated).async {
            guard let device = MTLCreateSystemDefaultDevice(),
                  let queue = device.makeCommandQueue() else {
                DispatchQueue.main.async {
                    benchmarkScore = 0
                    isRunning = false
                    hasRun = true
                }
                return
            }

            let bufferSize = 1_000_000
            let floatArray = (0..<bufferSize).map { Float($0) * 0.001 }
            guard let inputBuffer = device.makeBuffer(bytes: floatArray, length: bufferSize * MemoryLayout<Float>.stride, options: .storageModeShared),
                  let outputBuffer = device.makeBuffer(length: bufferSize * MemoryLayout<Float>.stride, options: .storageModeShared) else {
                DispatchQueue.main.async {
                    benchmarkScore = 0
                    isRunning = false
                    hasRun = true
                }
                return
            }

            let iterations = 50
            let startTime = CFAbsoluteTimeGetCurrent()

            for _ in 0..<iterations {
                guard let commandBuffer = queue.makeCommandBuffer(),
                      let blitEncoder = commandBuffer.makeBlitCommandEncoder() else { continue }
                blitEncoder.copy(from: inputBuffer, sourceOffset: 0, to: outputBuffer, destinationOffset: 0, size: bufferSize * MemoryLayout<Float>.stride)
                blitEncoder.endEncoding()
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }

            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            let throughputMBps = Double(bufferSize * MemoryLayout<Float>.stride * iterations) / totalTime / 1_000_000
            let score = Int(throughputMBps)

            DispatchQueue.main.async {
                benchmarkScore = score
                gpuInfo.append(("Throughput", String(format: "%.0f MB/s", throughputMBps)))
                gpuInfo.append(("Test Time", String(format: "%.2fs", totalTime)))
                isRunning = false
                hasRun = true
            }
        }
    }
}
