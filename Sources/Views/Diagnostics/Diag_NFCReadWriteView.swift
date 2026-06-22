import SwiftUI
import CoreNFC

struct Diag_NFCReadWriteView: View {
    @StateObject private var nfcManager = NFCDiagManager()

    var body: some View {
        List {
            Section("NFC Read/Write Test") {
                VStack(spacing: 12) {
                    Image(systemName: nfcManager.isSupported ? "wave.3.right.circle.fill" : "wave.3.right.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(nfcManager.isSupported ? .blue : .secondary)
                    Text(nfcManager.isSupported ? "NFC Available" : "NFC Not Available")
                        .font(.headline)
                    Text(nfcManager.isSupported ? "Ready to read and write NFC tags" : "This device does not support NFC")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("NFC Capabilities") {
                LabeledContent("NFC Reading") {
                    Text(NFCNDEFReaderSession.readingAvailable ? "Supported" : "Not Supported")
                        .foregroundStyle(NFCNDEFReaderSession.readingAvailable ? .green : .red)
                }
                LabeledContent("Tag Reading") {
                    Text(NFCTagReaderSession.readingAvailable ? "Supported" : "Not Supported")
                        .foregroundStyle(NFCTagReaderSession.readingAvailable ? .green : .red)
                }
                LabeledContent("NDEF Writing") {
                    Text(nfcManager.isSupported ? "Supported (iPhone 7+)" : "Not Supported")
                        .foregroundStyle(nfcManager.isSupported ? .green : .red)
                }
            }

            if nfcManager.isSupported {
                Section("Read NFC Tag") {
                    Button {
                        nfcManager.startReading()
                    } label: {
                        HStack {
                            Image(systemName: "wave.3.right")
                            Text("Scan NFC Tag")
                        }
                    }
                    .disabled(nfcManager.isScanning)

                    if nfcManager.isScanning {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text("Hold device near NFC tag...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !nfcManager.readResults.isEmpty {
                Section("Scan Results") {
                    ForEach(nfcManager.readResults, id: \.0) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.0)
                                .font(.subheadline.weight(.medium))
                            Text(result.1)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if let error = nfcManager.lastError {
                Section("Error") {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("NFC Tag Types") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("NDEF: Standard NFC Data Exchange Format", systemImage: "tag.fill")
                        .font(.caption)
                    Label("ISO 14443: Contactless smart cards", systemImage: "creditcard.fill")
                        .font(.caption)
                    Label("ISO 15693: Vicinity cards", systemImage: "barcode.viewfinder")
                        .font(.caption)
                    Label("FeliCa: Transit cards (Japan)", systemImage: "tram.fill")
                        .font(.caption)
                    Label("MiFare: Access cards and payments", systemImage: "key.card.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("NFC Read/Write")
        .navigationBarTitleDisplayMode(.inline)
    }
}

class NFCDiagManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var isSupported = false
    @Published var isScanning = false
    @Published var readResults: [(String, String)] = []
    @Published var lastError: String?

    private var session: NFCNDEFReaderSession?

    override init() {
        super.init()
        isSupported = NFCNDEFReaderSession.readingAvailable
    }

    func startReading() {
        guard NFCNDEFReaderSession.readingAvailable else {
            lastError = "NFC reading not available on this device"
            return
        }
        readResults = []
        lastError = nil
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your device near an NFC tag"
        session?.begin()
        isScanning = true
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            self.isScanning = false
            var results: [(String, String)] = []
            for (msgIdx, message) in messages.enumerated() {
                for (recIdx, record) in message.records.enumerated() {
                    let typeStr = String(data: record.type, encoding: .utf8) ?? "Unknown"
                    let payloadStr = String(data: record.payload, encoding: .utf8) ?? record.payload.map { String(format: "%02X", $0) }.joined(separator: " ")
                    results.append(("Record \(msgIdx+1).\(recIdx+1) [\(typeStr)]", payloadStr))
                }
            }
            if results.isEmpty {
                results.append(("Tag", "Empty NFC tag detected"))
            }
            self.readResults = results
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            let nfcError = error as NSError
            if nfcError.code != 200 {
                self.lastError = error.localizedDescription
            }
        }
    }
}
