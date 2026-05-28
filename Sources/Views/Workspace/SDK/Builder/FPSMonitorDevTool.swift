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
        VStack {
            ZStack {
                GeometryReader { geo in
                    Path { path in
                        guard viewModel.fpsHistory.count > 1 else { return }
                        let step = geo.size.width / CGFloat(viewModel.fpsHistory.count - 1)
                        let height = geo.size.height

                        path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat((viewModel.fpsHistory.first ?? 0)/100))))

                        for i in 1..<viewModel.fpsHistory.count {
                            path.addLine(to: CGPoint(x: CGFloat(i) * step, y: height * (1 - CGFloat(viewModel.fpsHistory[i]/100))))
                        }
                    }
                    .stroke(Color.accentColor, lineWidth: 2)
                }
                .frame(height: 150)
                .padding()

                Text("\(Int(viewModel.currentFPS)) FPS")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.currentFPS < 50 ? .red : .green)
            }

            Form {
                Section(header: Text("Statistics")) {
                    LabeledContent("Min FPS", value: "\(Int(viewModel.minFPS))")
                    LabeledContent("Max FPS", value: "\(Int(viewModel.maxFPS))")
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

#Preview {
    FPSMonitorView()
}
