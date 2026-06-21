import SwiftUI

struct AFMDashboardView: View {
    @StateObject private var service = AFMService.shared
    @StateObject private var sessionManager = AFMSessionManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.title2)
                        Text("System Status")
                            .font(.headline)
                        Spacer()
                        Circle()
                            .fill(service.isAvailable ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                    }

                    Text(service.availabilityMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !service.isAvailable {
                        Text("Ensure Apple Intelligence is enabled in System Settings and your device is compatible.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Session Info
                HStack(spacing: 15) {
                    InfoCard(title: "Session", value: sessionManager.sessionID.uuidString.prefix(8).lowercased(), icon: "clock", color: .blue)
                    InfoCard(title: "Messages", value: "\(sessionManager.messageCount)", icon: "bubble.left", color: .purple)
                }
                .padding(.horizontal)

                // Model Selection
                VStack(alignment: .leading) {
                    Text("Available On-Device Models")
                        .font(.headline)
                        .padding(.horizontal)

                    AFMModelSelectionView()
                }

                Button(action: {
                    sessionManager.startNewSession()
                }) {
                    Label("Reset Session", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}
