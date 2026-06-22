import SwiftUI
import QuartzCore

struct Diag_FrameDropView: View {
    @State private var currentFPS: Double = 0
    @State private var avgFPS: Double = 0
    @State private var droppedFrames: Int = 0
    @State private var totalFrames: Int = 0
    @State private var isMonitoring = false
    @State private var history: [FPSSample] = []
    @State private var minFPS: Double = 999
    @State private var maxFPS: Double = 0
    @State private var displayLink: CADisplayLink?
    @State private var lastTimestamp: CFTimeInterval = 0
    @State private var frameCount: Int = 0
    @State private var fpsUpdateTimer: Timer?

    struct FPSSample: Identifiable {
        let id = UUID()
        let timestamp: Date
        let fps: Double
        let dropped: Bool
    }

    var body: some View {
        Form {
            Section("Frame Rate") {
                VStack(spacing: 8) {
                    Text(String(format: "%.0f", currentFPS))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(fpsColor)
                    Text("FPS")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "Target: %d FPS", UIScreen.main.maximumFramesPerSecond))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Statistics") {
                LabeledContent("Average FPS") {
                    Text(String(format: "%.1f", avgFPS))
                        .monospacedDigit()
                        .foregroundStyle(avgFPS > 55 ? .green : .orange)
                }
                LabeledContent("Min FPS") {
                    Text(String(format: "%.1f", minFPS == 999 ? 0 : minFPS))
                        .monospacedDigit()
                        .foregroundStyle(.red)
                }
                LabeledContent("Max FPS") {
                    Text(String(format: "%.1f", maxFPS))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
                LabeledContent("Dropped Frames") {
                    Text("\(droppedFrames)")
                        .foregroundStyle(droppedFrames > 0 ? .red : .green)
                }
                LabeledContent("Total Frames") { Text("\(totalFrames)").monospacedDigit() }
                LabeledContent("Drop Rate") {
                    let rate = totalFrames > 0 ? Double(droppedFrames) / Double(totalFrames) * 100 : 0
                    Text(String(format: "%.2f%%", rate))
                        .monospacedDigit()
                        .foregroundStyle(rate > 5 ? .red : .green)
                }
            }

            Section("Display") {
                LabeledContent("Max Refresh Rate") {
                    Text("\(UIScreen.main.maximumFramesPerSecond) Hz")
                }
                LabeledContent("ProMotion") {
                    Text(UIScreen.main.maximumFramesPerSecond >= 120 ? "Supported" : "Not Supported")
                        .foregroundStyle(UIScreen.main.maximumFramesPerSecond >= 120 ? .green : .secondary)
                }
                LabeledContent("Render Scale") {
                    Text("\(Int(UIScreen.main.scale))x")
                }
            }

            if !history.isEmpty {
                Section("Recent (\(history.count) samples)") {
                    ForEach(history.suffix(15), id: \.id) { sample in
                        HStack {
                            Circle()
                                .fill(sample.dropped ? Color.red : Color.green)
                                .frame(width: 6, height: 6)
                            Text(sample.timestamp, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.0f FPS", sample.fps))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(sample.fps > 50 ? .green : (sample.fps > 30 ? .orange : .red))
                        }
                    }
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }

                if isMonitoring {
                    Button("Reset Statistics") {
                        droppedFrames = 0
                        totalFrames = 0
                        minFPS = 999
                        maxFPS = 0
                        history = []
                    }
                }
            }
        }
        .navigationTitle("Frame Drop Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private var fpsColor: Color {
        if currentFPS >= 55 { return .green }
        if currentFPS >= 30 { return .orange }
        return .red
    }

    private func startMonitoring() {
        isMonitoring = true
        frameCount = 0
        lastTimestamp = 0

        let link = CADisplayLink(target: FPSTracker.shared, selector: #selector(FPSTracker.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
        FPSTracker.shared.onUpdate = { fps in
            self.updateFPS(fps)
        }

        fpsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let fps = FPSTracker.shared.currentFPS
            self.updateFPS(fps)
        }
    }

    private func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
        fpsUpdateTimer?.invalidate()
        fpsUpdateTimer = nil
        isMonitoring = false
    }

    private func updateFPS(_ fps: Double) {
        currentFPS = fps
        totalFrames += 1

        let target = Double(UIScreen.main.maximumFramesPerSecond)
        let dropped = fps < target * 0.8
        if dropped { droppedFrames += 1 }

        if fps < minFPS && fps > 0 { minFPS = fps }
        if fps > maxFPS { maxFPS = fps }

        let allFPS = history.map(\.fps) + [fps]
        avgFPS = allFPS.reduce(0, +) / Double(allFPS.count)

        history.append(FPSSample(timestamp: Date(), fps: fps, dropped: dropped))
        if history.count > 120 { history.removeFirst() }
    }
}

final class FPSTracker: NSObject {
    static let shared = FPSTracker()
    var onUpdate: ((Double) -> Void)?
    var currentFPS: Double = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0

    @objc func tick(link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        frameCount += 1
        let elapsed = link.timestamp - lastTimestamp
        if elapsed >= 1.0 {
            currentFPS = Double(frameCount) / elapsed
            frameCount = 0
            lastTimestamp = link.timestamp
            DispatchQueue.main.async {
                self.onUpdate?(self.currentFPS)
            }
        }
    }
}
