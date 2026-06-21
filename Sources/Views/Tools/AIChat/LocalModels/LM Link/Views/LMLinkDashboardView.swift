import SwiftUI

struct LMLinkDashboardView: View {
    @StateObject private var connectionManager = LMConnectionManager.shared
    @StateObject private var authManager = LMLinkAuthManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Connection Status Card
                LMLinkConnectionStatusView()
                    .padding(.top)

                // Quick Info Grid
                HStack(spacing: 15) {
                    InfoCard(title: "Status", value: authManager.isLinked ? "Linked" : "Unlinked", icon: "link", color: authManager.isLinked ? .green : .red)
                    InfoCard(title: "Active Model", value: connectionManager.selectedModel?.name ?? "None", icon: "cpu", color: .blue)
                }
                .padding(.horizontal)

                // Device Summary
                VStack(alignment: .leading) {
                    Text("Selected Device")
                        .font(.headline)
                        .padding(.horizontal)

                    if let device = connectionManager.selectedDevice {
                        LMDeviceRowView(device: device)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        Text("No device selected. Go to Devices tab to select one.")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }

                Spacer()
            }
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
