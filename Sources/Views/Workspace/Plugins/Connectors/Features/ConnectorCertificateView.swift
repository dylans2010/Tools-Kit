
import SwiftUI

struct ConnectorCertificateView: View {
    @State private var certificates: [Cert] = []

    struct Cert: Identifiable {
        let id = UUID()
        var name: String
        var expiry: Date
    }

    var body: some View {
        List {
            Section("Client Certificates (mTLS)") {
                if certificates.isEmpty {
                    Text("No certificates installed.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(certificates) { cert in
                        HStack {
                            Image(systemName: "lock.shield")
                            VStack(alignment: .leading) {
                                Text(cert.name).bold()
                                Text("Expires: \(cert.expiry.formatted())").font(.caption2)
                            }
                        }
                    }
                }
            }

            Button("Import Certificate", systemImage: "tray.and.arrow.down") { }
        }
        .navigationTitle("Certificates")
    }
}
