import SwiftUI
import CoreMotion

struct Diag_MotionActivityView: View {
    @State private var currentActivity: String = "Unknown"
    @State private var confidence: String = "N/A"
    @State private var isStationary = false
    @State private var isWalking = false
    @State private var isRunning = false
    @State private var isCycling = false
    @State private var isAutomotive = false
    @State private var isMonitoring = false
    private let activityManager = CMMotionActivityManager()

    var body: some View {
        Form {
            Section("Current Activity") {
                VStack(spacing: 12) {
                    Image(systemName: activityIcon)
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text(currentActivity)
                        .font(.title2.weight(.semibold))
                    Text("Confidence: \(confidence)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Activity States") {
                activityRow("Stationary", icon: "figure.stand", active: isStationary)
                activityRow("Walking", icon: "figure.walk", active: isWalking)
                activityRow("Running", icon: "figure.run", active: isRunning)
                activityRow("Cycling", icon: "bicycle", active: isCycling)
                activityRow("Automotive", icon: "car.fill", active: isAutomotive)
            }

            Section("Availability") {
                LabeledContent("Motion Activity") {
                    Text(CMMotionActivityManager.isActivityAvailable() ? "Available" : "Unavailable")
                        .foregroundStyle(CMMotionActivityManager.isActivityAvailable() ? .green : .red)
                }
                LabeledContent("Step Counting") {
                    Text(CMPedometer.isStepCountingAvailable() ? "Available" : "Unavailable")
                        .foregroundStyle(CMPedometer.isStepCountingAvailable() ? .green : .red)
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Motion Activity")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopMonitoring() }
    }

    private func activityRow(_ title: String, icon: String, active: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(active ? .blue : .secondary)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
            Spacer()
            Circle()
                .fill(active ? Color.green : Color(.tertiarySystemFill))
                .frame(width: 10, height: 10)
        }
    }

    private var activityIcon: String {
        if isAutomotive { return "car.fill" }
        if isCycling { return "bicycle" }
        if isRunning { return "figure.run" }
        if isWalking { return "figure.walk" }
        return "figure.stand"
    }

    private func startMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        isMonitoring = true
        activityManager.startActivityUpdates(to: .main) { activity in
            guard let activity = activity else { return }
            isStationary = activity.stationary
            isWalking = activity.walking
            isRunning = activity.running
            isCycling = activity.cycling
            isAutomotive = activity.automotive

            if activity.automotive { currentActivity = "Driving" }
            else if activity.cycling { currentActivity = "Cycling" }
            else if activity.running { currentActivity = "Running" }
            else if activity.walking { currentActivity = "Walking" }
            else if activity.stationary { currentActivity = "Stationary" }
            else { currentActivity = "Unknown" }

            switch activity.confidence {
            case .low: confidence = "Low"
            case .medium: confidence = "Medium"
            case .high: confidence = "High"
            @unknown default: confidence = "Unknown"
            }
        }
    }

    private func stopMonitoring() {
        activityManager.stopActivityUpdates()
        isMonitoring = false
    }
}
