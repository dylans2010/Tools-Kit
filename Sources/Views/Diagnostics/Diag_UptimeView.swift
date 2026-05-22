import SwiftUI

struct Diag_UptimeView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var timer: Timer?
    @State private var uptimeString: String = ""
    @State private var uptimeSeconds: TimeInterval = 0

    var body: some View {
        Form {
            Section("System Uptime") {
                VStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)

                    Text(uptimeString)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))

                    Text("\(Int(uptimeSeconds)) seconds total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Breakdown") {
                let total = Int(uptimeSeconds)
                LabeledContent("Days") { Text("\(total / 86400)").monospacedDigit() }
                LabeledContent("Hours") { Text("\((total % 86400) / 3600)").monospacedDigit() }
                LabeledContent("Minutes") { Text("\((total % 3600) / 60)").monospacedDigit() }
                LabeledContent("Seconds") { Text("\(total % 60)").monospacedDigit() }
            }
        }
        .navigationTitle("System Uptime")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func startTimer() {
        updateUptime()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateUptime()
        }
    }

    private func updateUptime() {
        uptimeSeconds = ProcessInfo.processInfo.systemUptime
        uptimeString = service.formattedUptime
    }
}
