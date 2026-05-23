import SwiftUI
import Network

struct Diag_DNSLookupView: View {
    @State private var hostname: String = "apple.com"
    @State private var results: [DNSResult] = []
    @State private var isResolving = false
    @State private var lookupTime: TimeInterval = 0
    @State private var errorMessage: String?

    struct DNSResult: Identifiable {
        let id = UUID()
        let address: String
        let family: String
        let responseTime: TimeInterval
    }

    var body: some View {
        Form {
            Section("Lookup") {
                HStack {
                    TextField("Hostname", text: $hostname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Button {
                        performLookup()
                    } label: {
                        if isResolving {
                            ProgressView()
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    .disabled(hostname.isEmpty || isResolving)
                }
            }

            if let error = errorMessage {
                Section("Error") {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if !results.isEmpty {
                Section("Results (\(String(format: "%.0fms", lookupTime * 1000)))") {
                    ForEach(results) { result in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.address)
                                    .font(.system(.body, design: .monospaced))
                                Text(result.family)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(String(format: "%.0f", result.responseTime * 1000))ms")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Summary") {
                    LabeledContent("Total Records") { Text("\(results.count)") }
                    LabeledContent("IPv4 Records") {
                        Text("\(results.filter { $0.family == "IPv4" }.count)")
                    }
                    LabeledContent("IPv6 Records") {
                        Text("\(results.filter { $0.family == "IPv6" }.count)")
                    }
                    LabeledContent("Resolution Time") {
                        Text(String(format: "%.1f ms", lookupTime * 1000))
                            .monospacedDigit()
                    }
                }
            }

            Section("Quick Lookups") {
                ForEach(["google.com", "apple.com", "cloudflare.com", "github.com"], id: \.self) { host in
                    Button {
                        hostname = host
                        performLookup()
                    } label: {
                        HStack {
                            Text(host)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.right.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("DNS Lookup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performLookup() {
        isResolving = true
        errorMessage = nil
        results = []
        let startTime = CFAbsoluteTimeGetCurrent()

        DispatchQueue.global(qos: .userInitiated).async {
            let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
            var resolved = DarwinBoolean(false)
            CFHostStartInfoResolution(host, .addresses, nil)
            guard let addresses = CFHostGetAddressing(host, &resolved)?.takeUnretainedValue() as? [Data] else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to resolve \(hostname)"
                    self.isResolving = false
                }
                return
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            var resolvedResults: [DNSResult] = []

            for addressData in addresses {
                addressData.withUnsafeBytes { ptr in
                    guard let sockaddr = ptr.baseAddress?.assumingMemoryBound(to: sockaddr.self) else { return }
                    var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(sockaddr, socklen_t(addressData.count), &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) == 0 {
                        let address = String(cString: hostBuffer)
                        let family = sockaddr.pointee.sa_family == sa_family_t(AF_INET) ? "IPv4" : "IPv6"
                        resolvedResults.append(DNSResult(address: address, family: family, responseTime: elapsed))
                    }
                }
            }

            DispatchQueue.main.async {
                self.results = resolvedResults
                self.lookupTime = elapsed
                self.isResolving = false
            }
        }
    }
}
