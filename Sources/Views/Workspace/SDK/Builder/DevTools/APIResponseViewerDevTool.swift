import SwiftUI

struct APIResponseViewerTool: DevTool {
    let id = UUID()
    let name = "API Response Viewer"
    let category: DevToolCategory = .networking
    let icon = "doc.text.image"
    let description = "Fetch and display formatted API responses"
    func render() -> some View { APIResponseViewerDevToolView() }
}

struct APIResponseViewerDevToolView: View {
    @State private var urlString = "https://jsonplaceholder.typicode.com/posts/1"
    @State private var response = ""
    @State private var statusCode: Int?
    @State private var contentType = ""
    @State private var isLoading = false
    @State private var errorMsg: String?

    var body: some View {
        Form {
            Section("URL") {
                TextField("API URL", text: $urlString)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(action: fetch) {
                    HStack {
                        Label("Fetch", systemImage: "arrow.down.circle")
                        if isLoading { Spacer(); ProgressView().controlSize(.small) }
                    }
                }
                .disabled(urlString.isEmpty || isLoading)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if let statusCode {
                Section("Info") {
                    LabeledContent("Status", value: "\(statusCode)")
                    LabeledContent("Content-Type", value: contentType)
                    LabeledContent("Size", value: "\(response.utf8.count) bytes")
                }
            }
            if !response.isEmpty {
                Section("Response") {
                    Text(response.prefix(8000))
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("API Response Viewer")
    }

    private func fetch() {
        guard let url = URL(string: urlString) else { errorMsg = "Invalid URL"; return }
        isLoading = true; errorMsg = nil; response = ""; statusCode = nil
        URLSession.shared.dataTask(with: url) { data, resp, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error { errorMsg = error.localizedDescription; return }
                let httpResp = resp as? HTTPURLResponse
                statusCode = httpResp?.statusCode
                contentType = httpResp?.value(forHTTPHeaderField: "Content-Type") ?? "Unknown"
                guard let data else { response = "No data"; return }
                if let json = try? JSONSerialization.jsonObject(with: data),
                   let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                    response = String(data: pretty, encoding: .utf8) ?? "Cannot decode"
                } else {
                    response = String(data: data, encoding: .utf8) ?? "Binary data (\(data.count) bytes)"
                }
            }
        }.resume()
    }
}
