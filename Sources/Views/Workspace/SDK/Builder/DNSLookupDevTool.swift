import SwiftUI
import Darwin

struct DNSLookupDevTool: DevTool {
    let id = "dns-lookup"
    let name = "DNS Lookup"
    let category = DevToolCategory.networking
    let icon = "magnifyingglass.circle"
    let description = "Resolve hostnames and inspect DNS records"

    func render() -> some View {
        DNSLookupDevToolView()
    }
}

struct DNSLookupDevToolView: View {
    @StateObject private var viewModel = DNSLookupViewModel()

    var body: some View {
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

            Section {
                HStack {
                    Text("History")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        viewModel.history.removeAll()
                    }
                    .font(.caption)
                    .disabled(viewModel.history.isEmpty)
                }

                if viewModel.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock", description: Text("Your activity will appear here."))
                        .frame(height: 200)
                } else {
                    List {
                        ForEach(viewModel.history) { item in
                            Button {
                                viewModel.hostname = item.title
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.subheadline.bold())
                                    Text(item.detail)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .foregroundStyle(.secondary)
                                    Text(item.timestamp, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 300)
                }
            } header: {
                Text("History")
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

        let resolved = await resolve(hostname: hostname)

        await MainActor.run {
            self.results = resolved
            self.history.insert(HistoryItem(title: hostname, detail: "Resolved \(resolved.count) addresses"), at: 0)
            self.isLoading = false
        }
    }

    private func resolve(hostname: String) async -> [String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                var results: [String] = []
                var hints = addrinfo()
                hints.ai_family = AF_UNSPEC
                hints.ai_socktype = SOCK_STREAM

                var res: UnsafeMutablePointer<addrinfo>?
                let status = getaddrinfo(hostname, nil, &hints, &res)
                if status == 0, let head = res {
                    var current: UnsafeMutablePointer<addrinfo>? = head
                    while let info = current {
                        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        let nameInfoStatus = getnameinfo(
                            info.pointee.ai_addr,
                            socklen_t(info.pointee.ai_addrlen),
                            &hostBuffer,
                            socklen_t(hostBuffer.count),
                            nil,
                            0,
                            NI_NUMERICHOST
                        )
                        if nameInfoStatus == 0 {
                            let address = String(cString: hostBuffer)
                            if !results.contains(address) {
                                results.append(address)
                            }
                        }
                        current = info.pointee.ai_next
                    }
                    freeaddrinfo(head)
                }
                continuation.resume(returning: results)
            }
        }
    }
}

#Preview {
    DNSLookupDevToolView()
}
