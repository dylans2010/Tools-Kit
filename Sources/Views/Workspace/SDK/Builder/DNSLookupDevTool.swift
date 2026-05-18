import SwiftUI

struct DNSLookupDevTool: DevTool {
    let id = "dns-lookup"
    let name = "DNS Lookup"
    let category = DevToolCategory.networking
    let icon = "magnifyingglass.circle"
    let description = "Resolve hostnames and inspect DNS records"

    func render() -> some View {
        DNSLookupView()
    }
}

struct DNSLookupView: View {
    @StateObject private var viewModel = DNSLookupViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "DNS Lookup",
                description: "Resolve domain names to IP addresses and query specific record types.",
                icon: "magnifyingglass.circle"
            )
            .padding()

            Form {
                Section("Target") {
                    HStack {
                        TextField("google.com", text: $viewModel.hostname)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Picker("Type", selection: $viewModel.recordType) {
                            Text("A").tag(DNSRecordType.a)
                            Text("AAAA").tag(DNSRecordType.aaaa)
                            Text("MX").tag(DNSRecordType.mx)
                            Text("TXT").tag(DNSRecordType.txt)
                        }
                        .frame(width: 80)
                    }

                    Button("Resolve") {
                        Task { await viewModel.resolve() }
                    }
                    .disabled(viewModel.hostname.isEmpty || viewModel.isLoading)
                }

                if viewModel.isLoading {
                    ProgressView("Resolving...").frame(maxWidth: .infinity)
                }

                if !viewModel.results.isEmpty {
                    Section("Results") {
                        ForEach(viewModel.results, id: \.self) { result in
                            Text(result)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }

                Section("History") {
                    HistoryView(history: viewModel.history) { item in
                        viewModel.hostname = item.title
                    } onClear: {
                        viewModel.history.removeAll()
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}

enum DNSRecordType: String {
    case a = "A", aaaa = "AAAA", mx = "MX", txt = "TXT"
}

class DNSLookupViewModel: ObservableObject {
    @Published var hostname = "apple.com"
    @Published var recordType = DNSRecordType.a
    @Published var isLoading = false
    @Published var results: [String] = []
    @Published var history: [HistoryItem] = []

    func resolve() async {
        await MainActor.run { isLoading = true; results = [] }

        // Use Host to resolve
        let host = Host(name: hostname)
        let resolved = host.addresses

        await MainActor.run {
            self.results = resolved
            self.history.insert(HistoryItem(title: hostname, detail: "Resolved \(resolved.count) addresses"), at: 0)
            self.isLoading = false
        }
    }
}
