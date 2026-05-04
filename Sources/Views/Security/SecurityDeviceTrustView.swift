import SwiftUI
import UIKit

struct SecurityDeviceTrustView: View {
    @AppStorage("com.toolskit.security.trustedDevices") private var trustedDevicesData: Data = Data()
    @State private var trustedDevices: [TrustedDevice] = []

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
                                persist()
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section(footer: Text("Trusted devices can access your vault without additional email verification.")) {
                Button("Add Current Device") {
                    addCurrentDevice()
                }
                .disabled(trustedDevices.contains { $0.isCurrent })
            }
        }
        .navigationTitle("Trusted Devices")
        .onAppear(perform: loadTrustedDevices)
    }

    private func loadTrustedDevices() {
        trustedDevices = (try? JSONDecoder().decode([TrustedDevice].self, from: trustedDevicesData)) ?? []
    }

    private func persist() {
        trustedDevicesData = (try? JSONEncoder().encode(trustedDevices)) ?? Data()
    }

    private func addCurrentDevice() {
        trustedDevices = trustedDevices.map {
            TrustedDevice(id: $0.id, name: $0.name, fingerprint: $0.fingerprint, isCurrent: false)
        }
        let fingerprint = "SHA256:\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16))…"
        trustedDevices.insert(TrustedDevice(id: UUID(), name: UIDevice.current.name, fingerprint: fingerprint, isCurrent: true), at: 0)
        persist()
    }
}

struct TrustedDevice: Identifiable, Codable {
    let id: UUID
    let name: String
    let fingerprint: String
    let isCurrent: Bool
}
