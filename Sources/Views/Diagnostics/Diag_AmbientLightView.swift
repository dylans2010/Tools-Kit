import SwiftUI

struct Diag_AmbientLightView: View {
    @State private var brightness: CGFloat = UIScreen.main.brightness
    @State private var timer: Timer?
    @State private var isMonitoring = false
    @State private var history: [CGFloat] = []
    @State private var lightCondition: String = "Unknown"

    var body: some View {
        Form {
            Section("Ambient Light") {
                VStack(spacing: 16) {
                    Image(systemName: lightIcon)
                        .font(.system(size: 50))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.pulse, isActive: isMonitoring)

                    Text(lightCondition)
                        .font(.title2.bold())

                    Text("Screen Brightness: \(Int(brightness * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Brightness History") {
                if history.isEmpty {
                    Text("Start monitoring to see brightness changes")
                        .foregroundStyle(.secondary)
                } else {
                    Canvas { context, size in
                        guard history.count > 1 else { return }
                        var path = Path()
                        for (i, value) in history.enumerated() {
                            let xPos = CGFloat(i) / CGFloat(history.count - 1) * size.width
                            let yPos = size.height - (value * size.height)
                            if i == 0 { path.move(to: CGPoint(x: xPos, y: yPos)) }
                            else { path.addLine(to: CGPoint(x: xPos, y: yPos)) }
                        }
                        context.stroke(path, with: .color(.yellow), lineWidth: 2)
                    }
                    .frame(height: 120)
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "light.max")
                        Text(isMonitoring ? "Stop" : "Start Monitoring")
                    }
                }
            }

            Section {
                Text("This test monitors screen brightness as a proxy for ambient light. Enable Auto-Brightness in Settings for the most accurate results.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ambient Light")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopMonitoring() }
    }

    private var lightIcon: String {
        if brightness < 0.2 { return "moon.fill" }
        if brightness < 0.5 { return "sun.min.fill" }
        if brightness < 0.8 { return "sun.max.fill" }
        return "sun.max.trianglebadge.exclamationmark.fill"
    }

    private func classifyLight() {
        if brightness < 0.15 { lightCondition = "Very Dark" }
        else if brightness < 0.3 { lightCondition = "Dark" }
        else if brightness < 0.5 { lightCondition = "Dim" }
        else if brightness < 0.7 { lightCondition = "Normal" }
        else if brightness < 0.85 { lightCondition = "Bright" }
        else { lightCondition = "Very Bright" }
    }

    private func startMonitoring() {
        isMonitoring = true
        history.removeAll()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            brightness = UIScreen.main.brightness
            classifyLight()
            history.append(brightness)
            if history.count > 60 { history.removeFirst() }
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}
