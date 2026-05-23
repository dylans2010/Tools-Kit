import SwiftUI

struct Diag_ThermalHistoryView: View {
    @State private var thermalReadings: [(Date, ProcessInfo.ThermalState)] = []
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var currentState: ProcessInfo.ThermalState = .nominal

    var body: some View {
        Form {
            Section("Thermal Trend Monitor") {
                VStack(spacing: 12) {
                    Image(systemName: thermalIcon)
                        .font(.system(size: 52))
                        .foregroundStyle(thermalColor)
                    Text("Current: \(thermalString(currentState))")
                        .font(.headline)
                    Text("\(thermalReadings.count) readings collected")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Live Graph") {
                if thermalReadings.count > 1 {
                    GeometryReader { geo in
                        Path { path in
                            let stepX = geo.size.width / CGFloat(max(thermalReadings.count - 1, 1))
                            for (i, reading) in thermalReadings.enumerated() {
                                let y = geo.size.height * (1 - thermalLevel(reading.1))
                                let x = CGFloat(i) * stepX
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(thermalColor, lineWidth: 2)
                    }
                    .frame(height: 100)
                } else {
                    Text("Start monitoring to collect thermal data")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("Statistics") {
                if !thermalReadings.isEmpty {
                    let nominalCount = thermalReadings.filter { $0.1 == .nominal }.count
                    let fairCount = thermalReadings.filter { $0.1 == .fair }.count
                    let seriousCount = thermalReadings.filter { $0.1 == .serious }.count
                    let criticalCount = thermalReadings.filter { $0.1 == .critical }.count

                    LabeledContent("Nominal") { Text("\(nominalCount) (\(pct(nominalCount)))").foregroundStyle(.green) }
                    LabeledContent("Fair") { Text("\(fairCount) (\(pct(fairCount)))").foregroundStyle(.yellow) }
                    LabeledContent("Serious") { Text("\(seriousCount) (\(pct(seriousCount)))").foregroundStyle(.orange) }
                    LabeledContent("Critical") { Text("\(criticalCount) (\(pct(criticalCount)))").foregroundStyle(.red) }
                }
            }

            Section("Recent Readings") {
                ForEach(thermalReadings.suffix(10), id: \.0) { entry in
                    HStack {
                        Text(entry.0, style: .time).font(.caption.monospacedDigit())
                        Spacer()
                        Circle().fill(colorFor(entry.1)).frame(width: 8, height: 8)
                        Text(thermalString(entry.1)).font(.caption).foregroundStyle(colorFor(entry.1))
                    }
                }
            }

            Section {
                Button {
                    isMonitoring ? stopMonitoring() : startMonitoring()
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop" : "Start Monitoring")
                    }
                }
                if !thermalReadings.isEmpty {
                    Button(role: .destructive) { thermalReadings.removeAll() } label: { Text("Clear History") }
                }
            }
        }
        .navigationTitle("Thermal History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { currentState = ProcessInfo.processInfo.thermalState }
        .onDisappear { stopMonitoring() }
    }

    private var thermalIcon: String {
        switch currentState {
        case .nominal: return "thermometer.low"
        case .fair: return "thermometer.medium"
        case .serious: return "thermometer.high"
        case .critical: return "flame.fill"
        @unknown default: return "thermometer.medium"
        }
    }

    private var thermalColor: Color { colorFor(currentState) }

    private func colorFor(_ state: ProcessInfo.ThermalState) -> Color {
        switch state {
        case .nominal: return .green; case .fair: return .yellow; case .serious: return .orange; case .critical: return .red
        @unknown default: return .secondary
        }
    }

    private func thermalString(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"; case .fair: return "Fair"; case .serious: return "Serious"; case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private func thermalLevel(_ state: ProcessInfo.ThermalState) -> CGFloat {
        switch state { case .nominal: return 0.2; case .fair: return 0.4; case .serious: return 0.7; case .critical: return 1.0; @unknown default: return 0.5 }
    }

    private func pct(_ count: Int) -> String {
        guard !thermalReadings.isEmpty else { return "0%" }
        return String(format: "%.0f%%", Double(count) / Double(thermalReadings.count) * 100)
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            currentState = ProcessInfo.processInfo.thermalState
            thermalReadings.append((Date(), currentState))
            if thermalReadings.count > 200 { thermalReadings.removeFirst() }
        }
    }

    private func stopMonitoring() { timer?.invalidate(); timer = nil; isMonitoring = false }
}
