import SwiftUI

struct FPSMonitorTool: DevTool {
    let id = UUID()
    let name = "FPS Monitor"
    let category: DevToolCategory = .performance
    let icon = "speedometer"
    let description = "Monitor frames per second"
    func render() -> some View { FPSMonitorDevToolView() }
}

final class FPSCounter: ObservableObject {
    @Published var currentFPS: Int = 0
    @Published var history: [Int] = []
    @Published var minFPS: Int = 60
    @Published var maxFPS: Int = 0
    @Published var avgFPS: Double = 0

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount = 0

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(link: CADisplayLink) {
        if lastTimestamp == 0 { lastTimestamp = link.timestamp; return }
        frameCount += 1
        let elapsed = link.timestamp - lastTimestamp
        if elapsed >= 1.0 {
            let fps = Int(Double(frameCount) / elapsed)
            DispatchQueue.main.async {
                self.currentFPS = fps
                self.history.append(fps)
                if self.history.count > 60 { self.history.removeFirst() }
                self.minFPS = min(self.minFPS, fps)
                self.maxFPS = max(self.maxFPS, fps)
                self.avgFPS = Double(self.history.reduce(0, +)) / Double(self.history.count)
            }
            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }
}

struct FPSMonitorDevToolView: View {
    @StateObject private var counter = FPSCounter()

    var body: some View {
        Form {
            Section("Current FPS") {
                HStack {
                    Text("\(counter.currentFPS)")
                        .font(.system(.largeTitle, design: .monospaced).bold())
                        .foregroundStyle(fpsColor)
                    Text("FPS").font(.title3).foregroundStyle(.secondary)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Min: \(counter.minFPS)").font(.caption)
                        Text("Max: \(counter.maxFPS)").font(.caption)
                        Text("Avg: \(String(format: "%.1f", counter.avgFPS))").font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            Section("History") {
                if !counter.history.isEmpty {
                    GeometryReader { geo in
                        Path { path in
                            let step = geo.size.width / Double(max(1, counter.history.count - 1))
                            for (i, fps) in counter.history.enumerated() {
                                let x = Double(i) * step
                                let y = geo.size.height - (Double(fps) / 120.0) * geo.size.height
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(Color.green, lineWidth: 2)
                    }
                    .frame(height: 120)
                }
            }
        }
        .navigationTitle("FPS Monitor")
        .onAppear { counter.start() }
        .onDisappear { counter.stop() }
    }

    private var fpsColor: Color {
        counter.currentFPS >= 55 ? .green : counter.currentFPS >= 30 ? .orange : .red
    }
}
