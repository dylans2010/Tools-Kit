import SwiftUI

struct DNSLookupView: View {
    @StateObject private var backend = DNSLookupBackend()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Enter domain (e.g., google.com)", text: $backend.domain)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Button(action: { backend.lookup() }) {
                    if backend.isLoading {
                        ProgressView()
                    } else {
                        Text("Lookup")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isLoading || backend.domain.isEmpty)
            }

            if !backend.error.isEmpty {
                Text(backend.error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            List(backend.records) { record in
                VStack(alignment: .leading) {
                    HStack {
                        Text(record.name).font(.headline)
                        Spacer()
                        Text("Type: \(record.type)").font(.caption).foregroundColor(.secondary)
                    }
                    Text(record.data).font(.system(.body, design: .monospaced))
                    Text("TTL: \(record.TTL)").font(.caption2).foregroundColor(.secondary)
                }
            }
            .listStyle(PlainListStyle())
        }
        .padding()
        .navigationTitle("DNS Lookup")
    }
}

struct DNSLookupTool: Tool, Sendable {
    let name = "DNS Lookup"
    let icon = "magnifyingglass.circle"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Check DNS records for a domain"
    let requiresAPI = true
    var view: AnyView { AnyView(DNSLookupView()) }
}
