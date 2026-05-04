import SwiftUI

struct SecurityDeviceTrustView: View {
    @State private var trustedDevices: [TrustedDevice] = [
        TrustedDevice(id: UUID(), name: "Jules's iPhone 15", fingerprint: "SHA256:a1b2c3d4...", isCurrent: true),
        TrustedDevice(id: UUID(), name: "MacBook Pro M2", fingerprint: "SHA256:e5f6g7h8...", isCurrent: false)
    ]

    var body: some View {
        List {
            Section(header: Text("Trusted Devices")) {
                ForEach(trustedDevices) { device in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(device.name)
                                .font(.subheadline.bold())
                            if device.isCurrent {
                                Text("This Device")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        Text(device.fingerprint)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        if !device.isCurrent {
                            Button(role: .destructive) {
                                trustedDevices.removeAll { $0.id == device.id }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section(footer: Text("Trusted devices can access your vault without additional email verification.")) {
                Button("Add Current Device") {
                    // Logic to trust current device
                }
                .disabled(trustedDevices.contains { $0.isCurrent })
            }
        }
        .navigationTitle("Trusted Devices")
    }
}

struct TrustedDevice: Identifiable {
    let id: UUID
    let name: String
    let fingerprint: String
    let isCurrent: Bool
}
