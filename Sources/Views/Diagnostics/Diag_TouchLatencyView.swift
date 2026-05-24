import SwiftUI

struct Diag_TouchLatencyView: View {
    @State private var touchPoints: [(CGPoint, Date)] = []
    @State private var latencies: [Double] = []
    @State private var averageLatency: Double = 0
    @State private var minLatency: Double = 0
    @State private var maxLatency: Double = 0
    @State private var isTestActive = false
    @State private var targetPosition: CGPoint = .zero
    @State private var targetVisible = false
    @State private var targetAppearTime: Date?
    @State private var testCount = 0
    @State private var totalTests = 20
    @State private var lastTapAccuracy: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Results") {
                    LabeledContent("Tests Completed") {
                        Text("\(testCount)/\(totalTests)")
                            .monospacedDigit()
                    }
                    LabeledContent("Average Reaction Time") {
                        Text(averageLatency > 0 ? String(format: "%.0f ms", averageLatency) : "—")
                            .monospacedDigit()
                            .foregroundStyle(reactionColor(averageLatency))
                    }
                    LabeledContent("Best Time") {
                        Text(minLatency > 0 ? String(format: "%.0f ms", minLatency) : "—")
                            .monospacedDigit()
                            .foregroundStyle(.green)
                    }
                    LabeledContent("Worst Time") {
                        Text(maxLatency > 0 ? String(format: "%.0f ms", maxLatency) : "—")
                            .monospacedDigit()
                            .foregroundStyle(.red)
                    }
                    LabeledContent("Last Tap Accuracy") {
                        Text(lastTapAccuracy > 0 ? String(format: "%.1f px", lastTapAccuracy) : "—")
                            .monospacedDigit()
                    }
                }

                if !latencies.isEmpty {
                    Section("Distribution") {
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(latencies.indices, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(reactionColor(latencies[i]))
                                    .frame(height: CGFloat(min(latencies[i] / 5.0, 60)))
                            }
                        }
                        .frame(height: 60)
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button {
                        if isTestActive { stopTest() } else { startTest() }
                    } label: {
                        HStack {
                            Image(systemName: isTestActive ? "stop.circle.fill" : "hand.tap.fill")
                            Text(isTestActive ? "Stop Test" : "Start Touch Latency Test")
                        }
                    }

                    if isTestActive {
                        Text("Tap the green target as quickly as it appears!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if isTestActive {
                GeometryReader { geo in
                    ZStack {
                        Color(.systemGroupedBackground)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                handleTap(at: location)
                            }

                        if targetVisible {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 60, height: 60)
                                .shadow(color: .green.opacity(0.5), radius: 10)
                                .position(targetPosition)
                                .transition(.scale.combined(with: .opacity))
                        }

                        Text("Tap the target!")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .position(x: geo.size.width / 2, y: 30)
                    }
                    .onAppear {
                        showNextTarget(in: geo.size)
                    }
                }
                .frame(height: 300)
            }
        }
        .navigationTitle("Touch Latency")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func reactionColor(_ ms: Double) -> Color {
        if ms <= 0 { return .secondary }
        if ms < 200 { return .green }
        if ms < 350 { return .yellow }
        return .red
    }

    private func startTest() {
        latencies = []
        testCount = 0
        averageLatency = 0
        minLatency = 0
        maxLatency = 0
        isTestActive = true
    }

    private func stopTest() {
        isTestActive = false
        targetVisible = false
    }

    private func showNextTarget(in size: CGSize) {
        guard isTestActive, testCount < totalTests else {
            isTestActive = false
            return
        }

        targetVisible = false
        let delay = Double.random(in: 0.5...2.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard isTestActive else { return }
            let padding: CGFloat = 50
            let x = CGFloat.random(in: padding...(size.width - padding))
            let y = CGFloat.random(in: padding...(size.height - padding))
            targetPosition = CGPoint(x: x, y: y)
            withAnimation(.easeOut(duration: 0.1)) {
                targetVisible = true
            }
            targetAppearTime = Date()
        }
    }

    private func handleTap(at location: CGPoint) {
        guard targetVisible, let appearTime = targetAppearTime else { return }

        let reactionTime = Date().timeIntervalSince(appearTime) * 1000
        let distance = hypot(location.x - targetPosition.x, location.y - targetPosition.y)
        lastTapAccuracy = distance

        latencies.append(reactionTime)
        testCount += 1

        averageLatency = latencies.reduce(0, +) / Double(latencies.count)
        minLatency = latencies.min() ?? 0
        maxLatency = latencies.max() ?? 0

        withAnimation {
            targetVisible = false
        }

        if testCount < totalTests {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showNextTarget(in: CGSize(width: UIScreen.main.bounds.width, height: 300))
            }
        } else {
            isTestActive = false
        }
    }
}
