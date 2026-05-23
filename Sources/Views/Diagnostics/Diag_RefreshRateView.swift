import SwiftUI

struct Diag_RefreshRateView: View {
    @State private var displayLink: CADisplayLink?
    @State private var lastTimestamp: CFTimeInterval = 0
    @State private var currentFPS: Double = 0
    @State private var maxFPS: Double = 0
    @State private var samples: [Double] = []

    var body: some View {
        Form {
            Section("Refresh Rate") {
                VStack(spacing: 12) {
                    Text("\(Int(currentFPS)) Hz")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("Current Refresh Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Details") {
                LabeledContent("Max Detected") { Text("\(Int(maxFPS)) Hz").monospacedDigit() }
                LabeledContent("ProMotion") {
                    Text(maxFPS >= 120 ? "Supported" : "Not Detected")
                        .foregroundStyle(maxFPS >= 120 ? .green : .secondary)
                }
                LabeledContent("Samples") { Text("\(samples.count)").monospacedDigit() }
            }

            Section("Average") {
                let avg = samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count)
                LabeledContent("Average FPS") { Text("\(Int(avg)) Hz").monospacedDigit() }
            }
        }
        .navigationTitle("Refresh Rate")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        let link = CADisplayLink(target: DisplayLinkTarget { timestamp in
            if lastTimestamp > 0 {
                let fps = 1.0 / (timestamp - lastTimestamp)
                currentFPS = fps
                maxFPS = max(maxFPS, fps)
                if samples.count < 300 { samples.append(fps) }
            }
            lastTimestamp = timestamp
        }, selector: #selector(DisplayLinkTarget.step))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

private class DisplayLinkTarget: NSObject {
    let handler: (CFTimeInterval) -> Void
    init(handler: @escaping (CFTimeInterval) -> Void) { self.handler = handler }
    @objc func step(link: CADisplayLink) { handler(link.timestamp) }
}
