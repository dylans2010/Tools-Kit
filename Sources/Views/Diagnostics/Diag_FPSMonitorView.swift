import SwiftUI

struct Diag_FPSMonitorView: View {
    @State private var fps: Int = 0
    @State private var minFPS: Int = 999
    @State private var maxFPS: Int = 0
    @State private var fpsHistory: [Int] = []
    @State private var isMonitoring = false
    @State private var displayLink: CADisplayLink?
    @State private var lastTimestamp: CFTimeInterval = 0
    @State private var frameCount = 0

    var body: some View {
        Form {
            Section("Frame Rate") {
                VStack(spacing: 8) {
                    Text("\(fps)")
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundStyle(fpsColor)
                    Text("FPS")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Statistics") {
                LabeledContent("Current") {
                    Text("\(fps) FPS")
                        .monospacedDigit()
                        .foregroundStyle(fpsColor)
                }
                LabeledContent("Minimum") {
                    Text(minFPS == 999 ? "—" : "\(minFPS) FPS")
                        .monospacedDigit()
                }
                LabeledContent("Maximum") {
                    Text(maxFPS == 0 ? "—" : "\(maxFPS) FPS")
                        .monospacedDigit()
                }
                if !fpsHistory.isEmpty {
                    LabeledContent("Average") {
                        let avg = fpsHistory.reduce(0, +) / fpsHistory.count
                        Text("\(avg) FPS")
                            .monospacedDigit()
                    }
                }
            }

            if !fpsHistory.isEmpty {
                Section("History") {
                    Canvas { context, size in
                        let maxVal = CGFloat(fpsHistory.max() ?? 60)
                        guard fpsHistory.count > 1, maxVal > 0 else { return }
                        var path = Path()
                        for (i, val) in fpsHistory.enumerated() {
                            let xPos = CGFloat(i) / CGFloat(fpsHistory.count - 1) * size.width
                            let yPos = size.height - (CGFloat(val) / maxVal * size.height)
                            if i == 0 { path.move(to: CGPoint(x: xPos, y: yPos)) }
                            else { path.addLine(to: CGPoint(x: xPos, y: yPos)) }
                        }
                        context.stroke(path, with: .color(.green), lineWidth: 2)
                    }
                    .frame(height: 100)
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "gauge.with.dots.needle.67percent")
                        Text(isMonitoring ? "Stop" : "Start FPS Monitor")
                    }
                }
            }
        }
        .navigationTitle("FPS Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopMonitoring() }
    }

    private var fpsColor: Color {
        if fps >= 55 { return .green }
        if fps >= 30 { return .yellow }
        return .red
    }

    private func startMonitoring() {
        isMonitoring = true
        fpsHistory.removeAll()
        minFPS = 999
        maxFPS = 0
        frameCount = 0
        lastTimestamp = 0

        let link = CADisplayLink(target: FPSTarget {
            frameCount += 1
        } onSecond: { currentFPS in
            fps = currentFPS
            if currentFPS < minFPS { minFPS = currentFPS }
            if currentFPS > maxFPS { maxFPS = currentFPS }
            fpsHistory.append(currentFPS)
            if fpsHistory.count > 60 { fpsHistory.removeFirst() }
        }, selector: #selector(FPSTarget.tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
        isMonitoring = false
    }
}

private class FPSTarget: NSObject {
    var onFrame: () -> Void
    var onSecond: (Int) -> Void
    var lastTimestamp: CFTimeInterval = 0
    var frameCount = 0

    init(onFrame: @escaping () -> Void, onSecond: @escaping (Int) -> Void) {
        self.onFrame = onFrame
        self.onSecond = onSecond
    }

    @objc func tick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        frameCount += 1
        let elapsed = link.timestamp - lastTimestamp
        if elapsed >= 1.0 {
            onSecond(frameCount)
            frameCount = 0
            lastTimestamp = link.timestamp
        }
        onFrame()
    }
}
