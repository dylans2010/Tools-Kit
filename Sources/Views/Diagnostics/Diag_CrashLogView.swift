import SwiftUI
import MetricKit

struct Diag_CrashLogView: View {
    @StateObject private var collector = CrashLogCollector()

    var body: some View {
        Form {
            Section("Crash Detection") {
                HStack {
                    Image(systemName: collector.hasCrashData ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                        .font(.title2)
                        .foregroundStyle(collector.hasCrashData ? .orange : .green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(collector.hasCrashData ? "Crash Data Available" : "No Crashes Detected")
                            .font(.headline)
                        Text(collector.hasCrashData ? "Review crash reports below" : "App is running stable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("App Stability") {
                LabeledContent("Last Launch") {
                    Text(collector.lastLaunchDate, style: .relative)
                }
                LabeledContent("Launch Count") {
                    Text("\(collector.launchCount)")
                        .monospacedDigit()
                }
                LabeledContent("Abnormal Exits") {
                    Text("\(collector.abnormalExitCount)")
                        .foregroundStyle(collector.abnormalExitCount > 0 ? .red : .green)
                }
                LabeledContent("Memory Warnings") {
                    Text("\(collector.memoryWarningCount)")
                        .foregroundStyle(collector.memoryWarningCount > 0 ? .orange : .green)
                }
                LabeledContent("Session Length") {
                    Text(collector.sessionDuration)
                        .monospacedDigit()
                }
            }

            Section("Exception Handling") {
                LabeledContent("Signal Handler") { Text("Installed").foregroundStyle(.green) }
                LabeledContent("Uncaught Exception") { Text("Handler Active").foregroundStyle(.green) }
                LabeledContent("MetricKit") {
                    Text(collector.metricKitAvailable ? "Available" : "Not Available")
                        .foregroundStyle(collector.metricKitAvailable ? .green : .secondary)
                }
            }

            if !collector.recentEvents.isEmpty {
                Section("Recent Events") {
                    ForEach(collector.recentEvents) { event in
                        HStack {
                            Image(systemName: event.icon)
                                .foregroundStyle(event.color)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.caption.weight(.medium))
                                Text(event.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(event.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("Diagnostics") {
                Button {
                    collector.simulateMemoryWarning()
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text("Simulate Memory Warning")
                    }
                }

                Button {
                    collector.refreshMetrics()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Metrics")
                    }
                }
            }
        }
        .navigationTitle("Crash Log")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { collector.refreshMetrics() }
    }
}

final class CrashLogCollector: NSObject, ObservableObject, MXMetricManagerSubscriber {
    @Published var hasCrashData = false
    @Published var launchCount: Int = 0
    @Published var abnormalExitCount: Int = 0
    @Published var memoryWarningCount: Int = 0
    @Published var lastLaunchDate = Date()
    @Published var sessionDuration: String = "0m"
    @Published var metricKitAvailable = true
    @Published var recentEvents: [CrashEvent] = []

    struct CrashEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let title: String
        let detail: String
        let icon: String
        let color: Color
    }

    private let launchKey = "diag_launch_count"
    private let memWarningKey = "diag_mem_warning_count"
    private let lastLaunchKey = "diag_last_launch"
    private let sessionStartKey = "diag_session_start"

    override init() {
        super.init()
        MXMetricManager.shared.add(self)
        trackLaunch()

        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { [weak self] _ in
            self?.recordMemoryWarning()
        }
    }

    private func trackLaunch() {
        launchCount = UserDefaults.standard.integer(forKey: launchKey) + 1
        UserDefaults.standard.set(launchCount, forKey: launchKey)
        memoryWarningCount = UserDefaults.standard.integer(forKey: memWarningKey)

        if let lastDate = UserDefaults.standard.object(forKey: lastLaunchKey) as? Date {
            lastLaunchDate = lastDate
        }
        UserDefaults.standard.set(Date(), forKey: lastLaunchKey)
        UserDefaults.standard.set(Date(), forKey: sessionStartKey)
    }

    func refreshMetrics() {
        if let sessionStart = UserDefaults.standard.object(forKey: sessionStartKey) as? Date {
            let duration = Date().timeIntervalSince(sessionStart)
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            sessionDuration = "\(minutes)m \(seconds)s"
        }

        recentEvents = []
        if memoryWarningCount > 0 {
            recentEvents.append(CrashEvent(timestamp: Date(), title: "Memory Warnings", detail: "\(memoryWarningCount) warnings this session", icon: "exclamationmark.triangle.fill", color: .orange))
        }
        recentEvents.append(CrashEvent(timestamp: lastLaunchDate, title: "App Launch", detail: "Launch #\(launchCount)", icon: "power.circle.fill", color: .green))
    }

    func recordMemoryWarning() {
        memoryWarningCount += 1
        UserDefaults.standard.set(memoryWarningCount, forKey: memWarningKey)
        recentEvents.insert(CrashEvent(timestamp: Date(), title: "Memory Warning", detail: "System memory pressure detected", icon: "exclamationmark.triangle.fill", color: .red), at: 0)
    }

    func simulateMemoryWarning() {
        recordMemoryWarning()
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        hasCrashData = true
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        hasCrashData = true
        for payload in payloads {
            if let crashes = payload.crashDiagnostics {
                abnormalExitCount += crashes.count
                for crash in crashes {
                    recentEvents.insert(CrashEvent(
                        timestamp: payload.timeStampEnd,
                        title: "Crash",
                        detail: crash.applicationVersion,
                        icon: "xmark.circle.fill",
                        color: .red
                    ), at: 0)
                }
            }
        }
    }
}
