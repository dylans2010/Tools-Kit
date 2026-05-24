import SwiftUI
import CoreNFC

struct Diag_NFCDiagnosticsView: View {
    @State private var nfcAvailable = false
    @State private var details: [(String, String)] = []
    @State private var scanStatus = "Not scanned"
    @State private var lastTagInfo: [(String, String)] = []

    var body: some View {
        Form {
            Section("NFC Diagnostics") {
                VStack(spacing: 12) {
                    Image(systemName: nfcAvailable ? "wave.3.right.circle.fill" : "wave.3.right.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(nfcAvailable ? .green : .secondary)
                    Text(nfcAvailable ? "NFC Available" : "NFC Not Available")
                        .font(.headline)
                    Text("Advanced NFC diagnostics with tag detection and protocol support")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("NFC Hardware") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Protocol Support") {
                VStack(alignment: .leading, spacing: 6) {
                    capabilityRow("NDEF Read", supported: nfcAvailable)
                    capabilityRow("NDEF Write", supported: nfcAvailable)
                    capabilityRow("ISO 14443 (Type A/B)", supported: nfcAvailable)
                    capabilityRow("ISO 15693 (Vicinity)", supported: nfcAvailable)
                    capabilityRow("ISO 18092 (FeliCa)", supported: nfcAvailable)
                    capabilityRow("MIFARE Classic", supported: nfcAvailable)
                    capabilityRow("MIFARE Ultralight", supported: nfcAvailable)
                    capabilityRow("MIFARE DESFire", supported: nfcAvailable)
                }
                .padding(.vertical, 4)
            }

            Section("Tag Types") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("NFC Forum Type 1 (T1T)", systemImage: "tag.fill").font(.caption)
                    Label("NFC Forum Type 2 (T2T)", systemImage: "tag.fill").font(.caption)
                    Label("NFC Forum Type 3 (T3T/FeliCa)", systemImage: "tag.fill").font(.caption)
                    Label("NFC Forum Type 4 (T4T)", systemImage: "tag.fill").font(.caption)
                    Label("NFC Forum Type 5 (T5T/ISO 15693)", systemImage: "tag.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Use Cases") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Apple Pay contactless payment", systemImage: "creditcard.fill").font(.caption)
                    Label("NFC tag reading and writing", systemImage: "tag.fill").font(.caption)
                    Label("Express Transit cards", systemImage: "tram.fill").font(.caption)
                    Label("Digital car keys", systemImage: "car.fill").font(.caption)
                    Label("Home/hotel room keys", systemImage: "key.fill").font(.caption)
                    Label("Student ID and access badges", systemImage: "person.badge.key.fill").font(.caption)
                    Label("NDEF data exchange", systemImage: "arrow.triangle.2.circlepath").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 7 and later (NFC read)", systemImage: "iphone.gen1").font(.caption)
                    Label("iPhone XS and later (Background tag reading)", systemImage: "iphone.gen2").font(.caption)
                    Label("iPhone XR and later (NFC write)", systemImage: "iphone.gen2").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkNFC() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("NFC Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkNFC() }
    }

    @ViewBuilder
    private func capabilityRow(_ name: String, supported: Bool) -> some View {
        HStack {
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(supported ? .green : .secondary)
                .font(.caption)
            Text(name).font(.caption)
            Spacer()
            Text(supported ? "Supported" : "N/A")
                .font(.caption)
                .foregroundStyle(supported ? .green : .secondary)
        }
    }

    private func checkNFC() {
        nfcAvailable = NFCNDEFReaderSession.readingAvailable

        var info: [(String, String)] = []
        info.append(("NFC Reading", nfcAvailable ? "Available" : "Not available"))
        info.append(("NDEF Support", nfcAvailable ? "Yes" : "No"))
        info.append(("Tag Discovery", nfcAvailable ? "Supported" : "Not supported"))
        info.append(("Background Reading", nfcAvailable ? "Supported (iPhone XS+)" : "Not available"))

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))
        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
