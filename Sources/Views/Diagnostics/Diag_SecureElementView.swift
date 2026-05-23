import SwiftUI

struct Diag_SecureElementView: View {
    var body: some View {
        List {
            Section("Hardware Integrity") {
                HStack {
                    Image(systemName: "cpu.fill")
                    Text("Secure Element")
                    Spacer()
                    Text("Verified")
                        .foregroundStyle(.green)
                }

                HStack {
                    Image(systemName: "applepay")
                        .font(.title)
                    Text("Apple Pay Logic")
                    Spacer()
                    Text("Operational")
                        .foregroundStyle(.green)
                }
            }

            Section("Metrics") {
                LabeledContent("UID Status", value: "Fused")
                LabeledContent("Key Generation", value: "Available")
                LabeledContent("Storage", value: "AES-256 Encrypted")
            }
        }
        .navigationTitle("Secure Element")
    }
}
