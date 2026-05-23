import SwiftUI
import CoreNFC

struct Diag_NFCCheckView: View {
    @State private var nfcSupported = false
    @State private var nfcStatus: String = "Checking..."
    @State private var lastScanResult: String = ""
    @State private var isScanning = false

    var body: some View {
        Form {
            Section("NFC Status") {
                VStack(spacing: 12) {
                    Image(systemName: nfcSupported ? "wave.3.right.circle.fill" : "wave.3.right.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(nfcSupported ? .green : .secondary)
                    Text(nfcStatus)
                        .font(.headline)
                    Text(nfcSupported ? "Your device supports NFC" : "NFC is not available on this device")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Capabilities") {
                LabeledContent("NFC Reading") {
                    Text(nfcSupported ? "Supported" : "Not Supported")
                        .foregroundStyle(nfcSupported ? .green : .red)
                }
                LabeledContent("NDEF Tags") {
                    Text(nfcSupported ? "Supported" : "Not Supported")
                        .foregroundStyle(nfcSupported ? .green : .red)
                }
                LabeledContent("Tag Discovery") {
                    Text(nfcSupported ? "Available" : "Unavailable")
                        .foregroundStyle(nfcSupported ? .green : .red)
                }
            }

            if !lastScanResult.isEmpty {
                Section("Last Scan") {
                    Text(lastScanResult)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("NFC Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkNFC() }
    }

    private func checkNFC() {
        nfcSupported = NFCNDEFReaderSession.readingAvailable
        nfcStatus = nfcSupported ? "NFC Available" : "NFC Unavailable"
    }
}
