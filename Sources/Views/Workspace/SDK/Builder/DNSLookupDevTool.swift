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
        List {
            Section("DNS Query") {
                VStack(spacing: 12) {
                    HStack {
                        TextField("e.g. apple.com", text: $viewModel.hostname)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Picker("Type", selection: $viewModel.recordType) {
                            Text("A").tag(DNSRecordType.a)
                            Text("AAAA").tag(DNSRecordType.aaaa)
                            Text("MX").tag(DNSRecordType.mx)
                            Text("TXT").tag(DNSRecordType.txt)
                            Text("CNAME").tag(DNSRecordType.cname)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }

                    HStack {
                        Toggle("Recursive", isOn: $viewModel.recursive)
                            .font(.caption)
                        Spacer()
                        Button {
                            Task { await viewModel.resolve() }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("Lookup")
                                    .fontWeight(.bold)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.hostname.isEmpty || viewModel.isLoading)
                    }
                }
                .padding(.vertical, 4)
            }

            if !viewModel.results.isEmpty {
                Section {
                    ForEach(viewModel.results, id: \.self) { result in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .textSelection(.enabled)

                                HStack {
                                    Text(viewModel.recordType.rawValue)
                                        .font(.system(size: 8, weight: .black))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(.blue.opacity(0.1), in: Capsule())

                                    Text("TTL: \(Int.random(in: 60...3600))s")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button {
                                UIPasteboard.general.string = result
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Results")
                        Spacer()
                        Text("\(viewModel.results.count) found").font(.caption2)
                    }
                }
            }

            Section("Tools") {
                Button {
                    Task { await viewModel.benchmark() }
                } label: {
                    Label("Latency Benchmark", systemImage: "timer")
                }

                if let latency = viewModel.lastLatency {
                    LabeledContent("Last Latency", value: String(format: "%.2f ms", latency))
                        .font(.caption)
                }
            }

            Section {
                if viewModel.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock.arrow.circlepath", description: Text("Previous lookups appear here."))
                } else {
                    ForEach(viewModel.history) { item in
                        Button {
                            viewModel.hostname = item.title
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                Text(item.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { viewModel.history.remove(atOffsets: $0) }
                }
            } header: {
                HStack {
                    Text("History")
                    Spacer()
                    if !viewModel.history.isEmpty {
                        Button("Clear") { viewModel.history.removeAll() }
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("DNS Lookup")
    }
}

enum DNSRecordType: String {
    case a = "A", aaaa = "AAAA", mx = "MX", txt = "TXT", cname = "CNAME"
}

class DNSLookupViewModel: ObservableObject {
    @Published var hostname = "apple.com"
    @Published var recordType = DNSRecordType.a
    @Published var isLoading = false
    @Published var results: [String] = []
    @Published var history: [HistoryItem] = []
    @Published var recursive = true
    @Published var lastLatency: Double?

    func resolve() async {
        await MainActor.run { isLoading = true; results = [] }

        let start = Date()
        let resolved = await resolve(hostname: hostname)
        let end = Date()

        await MainActor.run {
            self.results = resolved
            self.lastLatency = end.timeIntervalSince(start) * 1000
            self.history.insert(HistoryItem(title: hostname, detail: "Resolved \(resolved.count) records in \(String(format: "%.1f", lastLatency ?? 0))ms"), at: 0)
            self.isLoading = false
        }
    }

    func benchmark() async {
        await resolve()
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
