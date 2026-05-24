import SwiftUI
import UIKit

struct Diag_ProximityStressView: View {
    @State private var isRunning = false
    @State private var proximityDetected = false
    @State private var toggleCount = 0
    @State private var lastToggleTime: Date?
    @State private var averageResponseTime: Double = 0
    @State private var responseTimes: [Double] = []
    @State private var sensorAvailable = false
    @State private var events: [ProximityEvent] = []
    @State private var statusText = "Ready"
    @State private var testStartTime: Date?

    struct ProximityEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let state: Bool
        let responseTime: Double
    }

    var body: some View {
        Form {
            Section("Sensor Status") {
                LabeledContent("Proximity Sensor") {
                    HStack(spacing: 4) {
                        Image(systemName: sensorAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(sensorAvailable ? .green : .red)
                        Text(sensorAvailable ? "Available" : "Not Detected")
                    }
                }
                LabeledContent("Current State") {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(proximityDetected ? .green : .gray)
                            .frame(width: 10, height: 10)
                        Text(proximityDetected ? "Object Detected" : "Clear")
                    }
                }
            }

            Section("Stress Test Results") {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 12)
                        Circle()
                            .fill(proximityDetected ? Color.green.opacity(0.2) : Color.clear)
                            .animation(.easeInOut(duration: 0.2), value: proximityDetected)
                        VStack(spacing: 2) {
                            Image(systemName: proximityDetected ? "hand.raised.fill" : "hand.raised")
                                .font(.title)
                                .foregroundStyle(proximityDetected ? .green : .secondary)
                            Text("\(toggleCount)")
                                .font(.title2.monospacedDigit().bold())
                            Text("toggles")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 130, height: 130)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                LabeledContent("Avg Response Time") {
                    Text(averageResponseTime > 0 ? String(format: "%.0f ms", averageResponseTime) : "—")
                        .monospacedDigit()
                }
                LabeledContent("Test Duration") {
                    if let start = testStartTime {
                        Text(start, style: .relative)
                            .monospacedDigit()
                    } else {
                        Text("—")
                    }
                }
            }

            if !events.isEmpty {
                Section("Recent Events") {
                    ForEach(events.prefix(15)) { event in
                        HStack {
                            Image(systemName: event.state ? "circle.fill" : "circle")
                                .foregroundStyle(event.state ? .green : .gray)
                                .font(.caption)
                            Text(event.state ? "Detected" : "Cleared")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.0f ms", event.responseTime))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(event.timestamp, style: .time)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section {
                Button {
                    if isRunning { stopTest() } else { startTest() }
                } label: {
                    HStack {
                        Image(systemName: isRunning ? "stop.circle.fill" : "hand.raised.fill")
                        Text(isRunning ? "Stop Test" : "Start Proximity Stress Test")
                    }
                }

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } footer: {
                Text("Wave your hand over the proximity sensor (near the earpiece) repeatedly. The test measures response time and reliability.")
            }
        }
        .navigationTitle("Proximity Stress")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkSensor() }
        .onDisappear { stopTest() }
    }

    private func checkSensor() {
        UIDevice.current.isProximityMonitoringEnabled = true
        sensorAvailable = UIDevice.current.isProximityMonitoringEnabled
        UIDevice.current.isProximityMonitoringEnabled = false
    }

    private func startTest() {
        isRunning = true
        toggleCount = 0
        responseTimes = []
        events = []
        averageResponseTime = 0
        testStartTime = Date()
        statusText = "Wave your hand over the sensor..."

        UIDevice.current.isProximityMonitoringEnabled = true
        lastToggleTime = Date()

        NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: UIDevice.current,
            queue: .main
        ) { _ in
            handleProximityChange()
        }
    }

    private func handleProximityChange() {
        let newState = UIDevice.current.proximityState
        let now = Date()
        let responseTime = lastToggleTime.map { now.timeIntervalSince($0) * 1000 } ?? 0

        proximityDetected = newState
        toggleCount += 1
        responseTimes.append(responseTime)
        averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)

        events.insert(ProximityEvent(
            timestamp: now,
            state: newState,
            responseTime: responseTime
        ), at: 0)

        lastToggleTime = now
        statusText = "\(toggleCount) toggles — avg \(String(format: "%.0f", averageResponseTime)) ms"
    }

    private func stopTest() {
        isRunning = false
        UIDevice.current.isProximityMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: nil)
        statusText = "Test complete — \(toggleCount) toggles recorded"
    }
}
