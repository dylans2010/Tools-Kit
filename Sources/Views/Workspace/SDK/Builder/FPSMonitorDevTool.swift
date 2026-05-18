import SwiftUI

struct FPSMonitorDevTool: DevTool {
    let id = "fps-monitor"
    let name = "FPS Monitor"
    let category = DevToolCategory.performance
    let icon = "gauge.with.needle"
    let description = "Monitor frames per second"

    func render() -> some View {
        FPSMonitorView()
    }
}

struct FPSMonitorView: View {
    @StateObject private var viewModel = FPSMonitorViewModel()

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 20)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.fps) / 60.0)
                    .stroke(viewModel.fps > 55 ? Color.green : (viewModel.fps > 30 ? Color.orange : Color.red), lineWidth: 20)
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text("\(Int(viewModel.fps))")
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                    Text("FPS")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, height: 200)
            .padding()

            Text("Real-time Main Thread Frame Rate")
                .foregroundStyle(.secondary)
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}

class FPSMonitorViewModel: ObservableObject {
    @Published var fps: Double = 0
    private var displayLink: CADisplayLink?
    private var lastTimestamp: TimeInterval = 0

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
    }

    @objc private func update(link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        let delta = link.timestamp - lastTimestamp
        fps = 1.0 / delta
        lastTimestamp = link.timestamp
    }
}
