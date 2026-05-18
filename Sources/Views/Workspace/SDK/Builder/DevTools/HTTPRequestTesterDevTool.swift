import SwiftUI

struct HTTPRequestTesterTool: DevTool {
    let id = UUID()
    let name = "HTTP Request Tester"
    let category: DevToolCategory = .networking
    let icon = "arrow.up.arrow.down.circle"
    let description = "Send HTTP requests and inspect responses"
    func render() -> some View { HTTPRequestTesterDevToolView() }
}

struct HTTPRequestTesterDevToolView: View {
    @State private var urlString = "https://httpbin.org/get"
    @State private var method = "GET"
    @State private var requestBody = ""
    @State private var statusCode: Int?
    @State private var responseBody = ""
    @State private var responseTime: TimeInterval?
    @State private var isLoading = false
    @State private var errorMsg: String?

    private let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]

    var body: some View {
        Form {
            Section("Request") {
                TextField("URL", text: $urlString)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Picker("Method", selection: $method) {
                    ForEach(methods, id: \.self) { Text($0).tag($0) }
                }
                if method == "POST" || method == "PUT" || method == "PATCH" {
                    TextEditor(text: $requestBody)
                        .frame(minHeight: 60)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            Section {
                Button(action: sendRequest) {
                    HStack {
                        Label("Send Request", systemImage: "paperplane.fill")
                        Spacer()
                        if isLoading { ProgressView().controlSize(.small) }
                    }
                }
                .disabled(urlString.isEmpty || isLoading)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if let statusCode {
                Section("Response") {
                    LabeledContent("Status") {
                        Text("\(statusCode)")
                            .foregroundStyle(statusCode < 400 ? .green : .red)
                            .bold()
                    }
                    if let responseTime {
                        LabeledContent("Time", value: String(format: "%.0fms", responseTime * 1000))
                    }
                    LabeledContent("Size", value: "\(responseBody.utf8.count) bytes")
                }
                Section("Body") {
                    Text(responseBody.prefix(5000))
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("HTTP Request Tester")
    }

    private func sendRequest() {
        guard let url = URL(string: urlString) else { errorMsg = "Invalid URL"; return }
        isLoading = true; errorMsg = nil; statusCode = nil; responseBody = ""
        var request = URLRequest(url: url)
        request.httpMethod = method
        if !requestBody.isEmpty { request.httpBody = requestBody.data(using: .utf8) }
        let start = Date()
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                responseTime = Date().timeIntervalSince(start)
                if let error { errorMsg = error.localizedDescription; return }
                statusCode = (response as? HTTPURLResponse)?.statusCode
                responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No data"
            }
        }.resume()
    }
}
