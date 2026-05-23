import SwiftUI

struct Diag_HTTPHeadersView: View {
    @State private var url: String = "https://httpbin.org/headers"
    @State private var responseHeaders: [HeaderEntry] = []
    @State private var requestHeaders: [HeaderEntry] = []
    @State private var statusCode: Int = 0
    @State private var responseTime: TimeInterval = 0
    @State private var isLoading = false
    @State private var errorMessage: String?

    struct HeaderEntry: Identifiable {
        let id = UUID()
        let key: String
        let value: String
    }

    var body: some View {
        Form {
            Section("Request") {
                HStack {
                    TextField("URL", text: $url)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Button {
                        fetchHeaders()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .disabled(url.isEmpty || isLoading)
                }
            }

            if let error = errorMessage {
                Section("Error") {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if statusCode > 0 {
                Section("Response") {
                    LabeledContent("Status") {
                        HStack {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text("\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))")
                                .font(.subheadline)
                        }
                    }
                    LabeledContent("Response Time") {
                        Text(String(format: "%.0f ms", responseTime * 1000))
                            .monospacedDigit()
                    }
                }
            }

            if !requestHeaders.isEmpty {
                Section("Request Headers (\(requestHeaders.count))") {
                    ForEach(requestHeaders) { header in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(header.key)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.blue)
                            Text(header.value)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if !responseHeaders.isEmpty {
                Section("Response Headers (\(responseHeaders.count))") {
                    ForEach(responseHeaders) { header in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(header.key)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.green)
                            Text(header.value)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("Quick URLs") {
                ForEach([
                    ("httpbin.org/headers", "Echo Headers"),
                    ("httpbin.org/ip", "My IP"),
                    ("httpbin.org/user-agent", "User Agent"),
                    ("apple.com", "Apple"),
                ], id: \.0) { endpoint, label in
                    Button {
                        url = "https://\(endpoint)"
                        fetchHeaders()
                    } label: {
                        HStack {
                            Text(label)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(endpoint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("HTTP Headers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusColor: Color {
        if statusCode >= 200 && statusCode < 300 { return .green }
        if statusCode >= 300 && statusCode < 400 { return .blue }
        if statusCode >= 400 && statusCode < 500 { return .orange }
        return .red
    }

    private func fetchHeaders() {
        guard let requestUrl = URL(string: url) else {
            errorMessage = "Invalid URL"
            return
        }
        isLoading = true
        errorMessage = nil
        responseHeaders = []
        requestHeaders = []
        statusCode = 0

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        // Capture request headers
        let defaultHeaders = [
            HeaderEntry(key: "Accept", value: "*/*"),
            HeaderEntry(key: "Accept-Language", value: Locale.current.identifier),
            HeaderEntry(key: "User-Agent", value: "ToolsKit-Diagnostics/1.0"),
        ]
        requestHeaders = defaultHeaders

        let startTime = CFAbsoluteTimeGetCurrent()

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                self.responseTime = CFAbsoluteTimeGetCurrent() - startTime
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    self.statusCode = httpResponse.statusCode
                    self.responseHeaders = httpResponse.allHeaderFields.map { key, value in
                        HeaderEntry(key: "\(key)", value: "\(value)")
                    }.sorted { $0.key < $1.key }
                }
            }
        }.resume()
    }
}
