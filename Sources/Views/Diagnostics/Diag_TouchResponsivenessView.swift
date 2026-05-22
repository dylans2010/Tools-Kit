import SwiftUI

struct Diag_TouchResponsivenessView: View {
    @State private var touchPoints: [CGPoint] = []
    @State private var hitCount = 0
    @State private var missCount = 0
    @State private var targetPosition = CGPoint(x: 150, y: 300)
    @State private var isTestActive = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                StatBox(title: "Hits", value: "\(hitCount)", color: .green)
                StatBox(title: "Misses", value: "\(missCount)", color: .red)
                StatBox(title: "Accuracy", value: accuracy, color: .blue)
            }
            .padding()

            GeometryReader { geo in
                ZStack {
                    Color(.systemGroupedBackground)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let point = value.location
                                    touchPoints.append(point)
                                    if touchPoints.count > 200 {
                                        touchPoints.removeFirst()
                                    }
                                }
                        )
                        .onTapGesture { location in
                            if isTestActive {
                                let distance = hypot(location.x - targetPosition.x, location.y - targetPosition.y)
                                if distance < 30 {
                                    hitCount += 1
                                    moveTarget(in: geo.size)
                                } else {
                                    missCount += 1
                                }
                            }
                        }

                    Path { path in
                        guard touchPoints.count > 1 else { return }
                        path.move(to: touchPoints[0])
                        for point in touchPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)

                    if isTestActive {
                        Circle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 44, height: 44)
                            .position(targetPosition)
                            .animation(.spring(response: 0.3), value: targetPosition)
                    }
                }
            }

            HStack(spacing: 16) {
                Button(isTestActive ? "Stop Test" : "Start Tap Test") {
                    isTestActive.toggle()
                    if isTestActive {
                        hitCount = 0
                        missCount = 0
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Clear Trail") {
                    touchPoints.removeAll()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Touch Responsiveness")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var accuracy: String {
        let total = hitCount + missCount
        guard total > 0 else { return "—" }
        return "\(Int(Double(hitCount) / Double(total) * 100))%"
    }

    private func moveTarget(in size: CGSize) {
        let margin: CGFloat = 30
        targetPosition = CGPoint(
            x: CGFloat.random(in: margin...(size.width - margin)),
            y: CGFloat.random(in: margin...(size.height - margin))
        )
    }
}

private struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}
