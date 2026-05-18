import SwiftUI

struct IPInfoTool: DevTool {
    let id = UUID()
    let name = "IP Info"
    let category: DevToolCategory = .networking
    let icon = "network"
    let description = "Get public IP address and network info"
    func render() -> some View { IPInfoDevToolView() }
}

struct IPInfoDevToolView: View {
    @State private var ipAddress = ""
    @State private var details: [(String, String)] = []
    @State private var isLoading = false
    @State private var errorMsg: String?

    var body: some View {
        Form {
            Section {
                Button(action: fetchIP) {
                    HStack {
                        Label("Get My IP Info", systemImage: "antenna.radiowaves.left.and.right")
                        if isLoading { Spacer(); ProgressView().controlSize(.small) }
                    }
                }
                .disabled(isLoading)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if !ipAddress.isEmpty {
                Section("Public IP") {
                    Text(ipAddress)
                        .font(.system(.title2, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            if !details.isEmpty {
                Section("Details") {
                    ForEach(Array(details.enumerated()), id: \.offset) { _, pair in
                        LabeledContent(pair.0, value: pair.1)
                    }
                }
            }
        }
        .navigationTitle("IP Info")
    }

    private func fetchIP() {
        isLoading = true; errorMsg = nil; details.removeAll()
        guard let url = URL(string: "https://ipinfo.io/json") else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error { errorMsg = error.localizedDescription; return }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    errorMsg = "Failed to parse response"; return
                }
                ipAddress = json["ip"] as? String ?? "Unknown"
                if let city = json["city"] as? String { details.append(("City", city)) }
                if let region = json["region"] as? String { details.append(("Region", region)) }
                if let country = json["country"] as? String { details.append(("Country", country)) }
                if let org = json["org"] as? String { details.append(("Organization", org)) }
                if let tz = json["timezone"] as? String { details.append(("Timezone", tz)) }
                if let loc = json["loc"] as? String { details.append(("Location", loc)) }
            }
        }.resume()
    }
}
