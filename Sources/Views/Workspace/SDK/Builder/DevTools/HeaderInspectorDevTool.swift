import SwiftUI

struct HeaderInspectorTool: DevTool {
    let id = UUID()
    let name = "Header Inspector"
    let category: DevToolCategory = .networking
    let icon = "list.bullet.rectangle"
    let description = "Inspect HTTP response headers"
    func render() -> some View { HeaderInspectorDevToolView() }
}

struct HeaderInspectorDevToolView: View {
    @State private var urlString = "https://httpbin.org/headers"
    @State private var headers: [(String, String)] = []
    @State private var isLoading = false
    @State private var errorMsg: String?

    var body: some View {
        Form {
            Section("URL") {
                TextField("URL", text: $urlString)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(action: fetchHeaders) {
                    HStack {
                        Label("Fetch Headers", systemImage: "arrow.down.doc")
                        if isLoading { Spacer(); ProgressView().controlSize(.small) }
                    }
                }
                .disabled(urlString.isEmpty || isLoading)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if !headers.isEmpty {
                Section("Response Headers (\(headers.count))") {
                    ForEach(Array(headers.enumerated()), id: \.offset) { _, pair in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pair.0).font(.caption.bold()).foregroundStyle(.accent)
                            Text(pair.1).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .navigationTitle("Header Inspector")
    }

    private func fetchHeaders() {
        guard let url = URL(string: urlString) else { errorMsg = "Invalid URL"; return }
        isLoading = true; errorMsg = nil; headers.removeAll()
        URLSession.shared.dataTask(with: url) { _, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error { errorMsg = error.localizedDescription; return }
                if let httpResp = response as? HTTPURLResponse {
                    headers = httpResp.allHeaderFields.map { (String(describing: $0.key), String(describing: $0.value)) }
                        .sorted { $0.0 < $1.0 }
                }
            }
        }.resume()
    }
}
