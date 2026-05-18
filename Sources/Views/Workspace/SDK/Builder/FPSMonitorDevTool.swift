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
        VStack(spacing: 0) {
            DevToolHeader(
                title: "FPS Monitor",
                description: "Track frame rate consistency and detect dropped frames for smooth UI interactions.",
                icon: "speedometer"
            )
            .padding()

            VStack {
                ZStack {
                    UsageChart(data: viewModel.fpsHistory)
                        .frame(height: 150)
                        .padding()

                    Text("\(Int(viewModel.currentFPS)) FPS")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.currentFPS < 50 ? .red : .green)
                }

                Form {
                    Section("Statistics") {
                        LabeledContent("Min FPS", value: "\(Int(viewModel.minFPS))")
                        LabeledContent("Max FPS", value: "\(Int(viewModel.maxFPS))")
                    }
                }
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}

class FPSMonitorViewModel: ObservableObject {
    @Published var currentFPS: Double = 60
    @Published var minFPS: Double = 60
    @Published var maxFPS: Double = 0
    @Published var fpsHistory: [Double] = Array(repeating: 60, count: 50)

    private var displayLink: CADisplayLink?
    private var lastTimestamp: TimeInterval = 0

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func update(link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        let delta = link.timestamp - lastTimestamp
        let fps = 1.0 / delta
        lastTimestamp = link.timestamp

        currentFPS = fps
        if fps < minFPS { minFPS = fps }
        if fps > maxFPS { maxFPS = fps }

        fpsHistory.removeFirst()
        fpsHistory.append(fps)
    }
}
