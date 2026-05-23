import SwiftUI

struct Diag_BackgroundRefreshView: View {
    @State private var refreshStatus: String = "Checking..."
    @State private var backgroundTasks: [(String, Bool)] = []

    var body: some View {
        Form {
            Section("Background App Refresh") {
                VStack(spacing: 12) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 48))
                        .foregroundStyle(statusColor)
                    Text(refreshStatus)
                        .font(.headline)
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("System Status") {
                LabeledContent("Background Refresh") {
                    Text(refreshStatus)
                        .foregroundStyle(statusColor)
                }
                LabeledContent("Low Power Mode") {
                    let lpm = ProcessInfo.processInfo.isLowPowerModeEnabled
                    Text(lpm ? "Enabled (limits refresh)" : "Disabled")
                        .foregroundStyle(lpm ? .orange : .green)
                }
                LabeledContent("Multitasking") {
                    Text(UIDevice.current.isMultitaskingSupported ? "Supported" : "Not Supported")
                        .foregroundStyle(UIDevice.current.isMultitaskingSupported ? .green : .red)
                }
            }

            Section("Background Capabilities") {
                capabilityRow("Background Fetch", icon: "arrow.down.circle", available: true)
                capabilityRow("Remote Notifications", icon: "bell.badge", available: true)
                capabilityRow("Background Processing", icon: "gearshape.2", available: true)
                capabilityRow("Background URL Session", icon: "network", available: true)
            }

            Section {
                Button("Refresh Status") { checkStatus() }
            }
        }
        .navigationTitle("Background Refresh")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkStatus() }
    }

    private func capabilityRow(_ title: String, icon: String, available: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
            Spacer()
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(available ? .green : .red)
        }
    }

    private func checkStatus() {
        switch UIApplication.shared.backgroundRefreshStatus {
        case .available:
            refreshStatus = "Available"
        case .denied:
            refreshStatus = "Denied"
        case .restricted:
            refreshStatus = "Restricted"
        @unknown default:
            refreshStatus = "Unknown"
        }
    }

    private var statusIcon: String {
        switch refreshStatus {
        case "Available": return "arrow.clockwise.circle.fill"
        case "Denied": return "nosign"
        case "Restricted": return "lock.circle.fill"
        default: return "questionmark.circle"
        }
    }

    private var statusColor: Color {
        switch refreshStatus {
        case "Available": return .green
        case "Denied": return .red
        case "Restricted": return .orange
        default: return .secondary
        }
    }

    private var statusDescription: String {
        switch refreshStatus {
        case "Available": return "Apps can refresh content in the background"
        case "Denied": return "Background refresh is disabled in Settings"
        case "Restricted": return "Background refresh is restricted by system policy"
        default: return "Unable to determine status"
        }
    }
}
