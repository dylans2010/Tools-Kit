import SwiftUI

struct SecurityDeviceTrustView: View {
    @StateObject private var store = SecurityDeviceSessionStore.shared

    var body: some View {
        List {
            Section(header: Text("Trusted Devices")) {
                ForEach(store.trustedDevices.sorted(by: { $0.trustedAt > $1.trustedAt })) { device in
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
                        Text("Trusted \(device.trustedAt, style: .date)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        if !device.isCurrent {
                            Button(role: .destructive) {
                                store.removeTrustedDevice(device)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section(footer: Text("Trusted devices can access your vault without additional verification.")) {
                Button("Trust Current Device") {
                    store.trustCurrentDevice()
                }
            }
        }
        .navigationTitle("Trusted Devices")
    }
}
