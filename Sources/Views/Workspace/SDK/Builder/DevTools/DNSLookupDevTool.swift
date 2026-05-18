import SwiftUI

struct DNSLookupTool: DevTool {
    let id = UUID()
    let name = "DNS Lookup"
    let category: DevToolCategory = .networking
    let icon = "magnifyingglass.circle"
    let description = "Perform DNS lookups for hostnames"
    func render() -> some View { DNSLookupDevToolView() }
}

struct DNSLookupDevToolView: View {
    @State private var hostname = "apple.com"
    @State private var results: [String] = []
    @State private var isLoading = false
    @State private var errorMsg: String?

    var body: some View {
        Form {
            Section("Hostname") {
                TextField("Enter hostname", text: $hostname)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(action: lookup) {
                    HStack {
                        Label("Lookup", systemImage: "magnifyingglass")
                        if isLoading { Spacer(); ProgressView().controlSize(.small) }
                    }
                }
                .disabled(hostname.isEmpty || isLoading)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if !results.isEmpty {
                Section("Results (\(results.count) addresses)") {
                    ForEach(results, id: \.self) { addr in
                        HStack {
                            Image(systemName: addr.contains(":") ? "6.circle" : "4.circle")
                                .foregroundStyle(.accent)
                            Text(addr).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .navigationTitle("DNS Lookup")
    }

    private func lookup() {
        isLoading = true; errorMsg = nil; results.removeAll()
        DispatchQueue.global().async {
            let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
            var resolved = DarwinBoolean(false)
            CFHostStartInfoResolution(host, .addresses, nil)
            guard let addresses = CFHostGetAddressing(host, &resolved)?.takeUnretainedValue() as? [Data] else {
                DispatchQueue.main.async { isLoading = false; errorMsg = "Resolution failed" }
                return
            }
            let resolved_addrs = addresses.compactMap { data -> String? in
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = data.withUnsafeBytes { ptr -> Int32 in
                    guard let addr = ptr.baseAddress?.assumingMemoryBound(to: sockaddr.self) else { return -1 }
                    return getnameinfo(addr, socklen_t(data.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                }
                return result == 0 ? String(cString: hostname) : nil
            }
            DispatchQueue.main.async {
                isLoading = false
                results = resolved_addrs
                if results.isEmpty { errorMsg = "No addresses found" }
            }
        }
    }
}
