import SwiftUI

struct DNSLookupDevTool: DevTool {
    let id = "dns-lookup"
    let name = "DNS Lookup"
    let category = DevToolCategory.networking
    let icon = "text.magnifyingglass"
    let description = "Lookup DNS records"

    func render() -> some View {
        DNSLookupView()
    }
}

struct DNSLookupView: View {
    @StateObject private var viewModel = DNSLookupViewModel()

    var body: some View {
        Form {
            Section("Hostname") {
                TextField("google.com", text: $viewModel.hostname)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Lookup") {
                    viewModel.lookup()
                }
            }

            Section("Results (A Records)") {
                if viewModel.results.isEmpty {
                    Text("No records found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.results, id: \.self) { ip in
                        Text(ip)
                            .font(.monospaced(.body)())
                    }
                }
            }
        }
    }
}

class DNSLookupViewModel: ObservableObject {
    @Published var hostname = "google.com"
    @Published var results: [String] = []

    func lookup() {
        let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as? [Data] {
            results = addresses.compactMap { data in
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                data.withUnsafeBytes { ptr in
                    let addr = ptr.baseAddress?.assumingMemoryBound(to: sockaddr.self)
                    getnameinfo(addr, socklen_t(data.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                }
                return String(cString: hostname)
            }
        } else {
            results = []
        }
    }
}
