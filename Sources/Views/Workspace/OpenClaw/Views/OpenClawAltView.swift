import SwiftUI

struct OpenClawAltMethod: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let security: String
    let reliability: String
    let difficulty: String
    let setupTime: String
    let reconnect: Bool
    let crossPlatform: Bool
    let isRecommended: Bool
    let availability: String
    let status: String
}

struct OpenClawAltView: View {
    let methods: [OpenClawAltMethod] = [
        OpenClawAltMethod(
            name: "Trusted LAN",
            description: "Native approval dialog on your Mac. Easiest for daily use.",
            security: "High",
            reliability: "Excellent",
            difficulty: "Easy",
            setupTime: "30s",
            reconnect: true,
            crossPlatform: true,
            isRecommended: true,
            availability: "Available",
            status: "Not Paired"
        ),
        OpenClawAltMethod(
            name: "Pairing Code",
            description: "Enter a 6-digit code shown on your Mac screen.",
            security: "High",
            reliability: "Good",
            difficulty: "Medium",
            setupTime: "1m",
            reconnect: true,
            crossPlatform: true,
            isRecommended: false,
            availability: "Available",
            status: "Not Paired"
        ),
        OpenClawAltMethod(
            name: "QR Code",
            description: "Scan a QR code displayed on your Mac.",
            security: "High",
            reliability: "Good",
            difficulty: "Easy",
            setupTime: "15s",
            reconnect: true,
            crossPlatform: true,
            isRecommended: false,
            availability: "Available",
            status: "Not Paired"
        ),
        OpenClawAltMethod(
            name: "Manual Token",
            description: "Copy-paste a long-lived pairing token manually.",
            security: "Very High",
            reliability: "Excellent",
            difficulty: "Hard",
            setupTime: "2m",
            reconnect: true,
            crossPlatform: true,
            isRecommended: false,
            availability: "Available",
            status: "Not Paired"
        ),
        OpenClawAltMethod(
            name: "Local Approval",
            description: "Just connect and allow the unknown device on your Mac.",
            security: "Medium",
            reliability: "Good",
            difficulty: "Very Easy",
            setupTime: "10s",
            reconnect: true,
            crossPlatform: true,
            isRecommended: false,
            availability: "Available",
            status: "Not Paired"
        )
    ]

    var body: some View {
        List {
            Section {
                Text("Choose an alternative pairing method if the default handshake fails or if you prefer a different security model.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(methods) { method in
                NavigationLink {
                    methodDetailView(for: method)
                } label: {
                    OpenClawMethodCard(method: method)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Alternatives")
    }

    @ViewBuilder
    private func methodDetailView(for method: OpenClawAltMethod) -> some View {
        switch method.name {
        case "Trusted LAN":
            TrustedLANView()
        case "Pairing Code":
            PairingCodeView()
        case "QR Code":
            QRCodeView()
        case "Manual Token":
            ManualTokenView()
        case "Local Approval":
            LocalApprovalView()
        default:
            VStack {
                Text("\(method.name) Implementation")
                    .font(.title)
                Text("Coming soon in subsequent steps.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle(method.name)
        }
    }
}

struct OpenClawMethodCard: View {
    let method: OpenClawAltMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(method.name)
                    .font(.headline)
                Text(method.availability)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())

                if method.isRecommended {
                    Text("RECOMMENDED")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                Spacer()
                Text(method.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(method.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    metadataItem(label: "Security", value: method.security, icon: "lock.shield")
                    metadataItem(label: "Reliability", value: method.reliability, icon: "checkmark.circle")
                }
                GridRow {
                    metadataItem(label: "Difficulty", value: method.difficulty, icon: "gauge.with.dots.needle.33percent")
                    metadataItem(label: "Setup Time", value: method.setupTime, icon: "clock")
                }
            }

            HStack {
                Label("Auto-Reconnect", systemImage: method.reconnect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(method.reconnect ? .green : .red)
                Spacer()
                Label("Cross-Platform", systemImage: method.crossPlatform ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(method.crossPlatform ? .green : .red)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metadataItem(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.bold())
            }
        }
    }
}
