import SwiftUI

struct FPSMonitorDevTool: DevTool {
    let id = "fps-monitor"
    let name = "FPS Monitor"
    let category = DevToolCategory.performance
    let icon = "speedometer"
    let description = "Monitor UI frame rate and drop frames"

    func render() -> some View {
        FPSMonitorView()
    }
}

struct FPSMonitorView: View {
    @StateObject private var viewModel = FPSMonitorViewModel()

    var body: some View {
        List {
            Section("Live Performance") {
                VStack(spacing: 20) {
                    ZStack {
                        chartView
                            .frame(height: 120)

                        VStack {
                            Text("\(Int(viewModel.currentFPS))")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundStyle(fpsColor)
                            Text("FPS")
                                .font(.caption.bold())
                                .foregroundStyle(fpsColor.opacity(0.8))
                        }
                    }

                    HStack(spacing: 12) {
                        StatCard(label: "Minimum", value: "\(Int(viewModel.minFPS))", color: .red)
                        StatCard(label: "Maximum", value: "\(Int(viewModel.maxFPS))", color: .green)
                        StatCard(label: "Avg", value: "\(Int(viewModel.avgFPS))", color: .blue)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Jank & Stutter") {
                LabeledContent("Dropped Frames", value: "\(viewModel.droppedFrames)")
                LabeledContent("Stutter Rate", value: String(format: "%.1f%%", viewModel.stutterRate))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Frame Time History").font(.caption).foregroundStyle(.secondary)
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(viewModel.frameTimeHistory.suffix(40), id: \.self) { time in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(time > 0.0167 ? Color.orange : Color.green)
                                .frame(width: 4, height: CGFloat(min(40, time * 1000)))
                        }
                    }
                    .frame(height: 40)
                }
                .padding(.vertical, 4)
            }

            Section("Advanced Metrics") {
                LabeledContent("Frame Time", value: String(format: "%.2f ms", viewModel.currentFrameTime * 1000))
                LabeledContent("Display Refresh Rate", value: "\(Int(UIScreen.main.maximumFramesPerSecond)) Hz")
            }

            Section {
                Button(role: .destructive) {
                    viewModel.resetStats()
                } label: {
                    Label("Reset Statistics", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("FPS Monitor")
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var chartView: some View {
        GeometryReader { geo in
            Path { path in
                guard viewModel.fpsHistory.count > 1 else { return }
                let step = geo.size.width / CGFloat(viewModel.fpsHistory.count - 1)
                let height = geo.size.height

                path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat(viewModel.fpsHistory.first ?? 0)/120)))

                for i in 1..<viewModel.fpsHistory.count {
                    path.addLine(to: CGPoint(x: CGFloat(i) * step, y: height * (1 - CGFloat(viewModel.fpsHistory[i]/120))))
                }
            }
            .stroke(fpsColor.gradient, lineWidth: 3)
        }
    }

    private var fpsColor: Color {
        if viewModel.currentFPS < 30 { return .red }
        if viewModel.currentFPS < 55 { return .orange }
        return .green
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.headline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

class FPSMonitorViewModel: ObservableObject {
    @Published var currentFPS: Double = 60
    @Published var minFPS: Double = 60
    @Published var maxFPS: Double = 0
    @Published var avgFPS: Double = 60
    @Published var fpsHistory: [Double] = Array(repeating: 60, count: 60)
    @Published var frameTimeHistory: [Double] = []
    @Published var currentFrameTime: Double = 0
    @Published var droppedFrames: Int = 0
    @Published var stutterRate: Double = 0

    private var displayLink: CADisplayLink?
    private var lastTimestamp: TimeInterval = 0
    private var totalFrames: Int = 0
    private var totalFPS: Double = 0

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    func resetStats() {
        minFPS = 60
        maxFPS = 0
        totalFrames = 0
        totalFPS = 0
        droppedFrames = 0
        stutterRate = 0
        frameTimeHistory.removeAll()
    }

    @objc private func update(link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        let delta = link.timestamp - lastTimestamp
        let fps = min(120, 1.0 / delta)
        lastTimestamp = link.timestamp
        currentFrameTime = delta

        currentFPS = fps
        totalFrames += 1
        totalFPS += fps
        avgFPS = totalFPS / Double(totalFrames)

        if fps < minFPS { minFPS = fps }
        if fps > maxFPS { maxFPS = fps }

        if delta > 0.0167 * 1.5 { // Threshold for dropped frame at 60Hz
            droppedFrames += 1
        }

        stutterRate = Double(droppedFrames) / Double(totalFrames) * 100

        fpsHistory.removeFirst()
        fpsHistory.append(fps)

        frameTimeHistory.append(delta)
        if frameTimeHistory.count > 100 { frameTimeHistory.removeFirst() }
    }
}

#Preview {
    FPSMonitorView()
}
