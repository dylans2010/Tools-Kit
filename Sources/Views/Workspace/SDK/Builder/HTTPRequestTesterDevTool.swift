import SwiftUI

struct HTTPRequestTesterDevTool: DevTool {
    let id = "http-request-tester"
    let name = "HTTP Request Tester"
    let category = DevToolCategory.networking
    let icon = "network"
    let description = "Advanced HTTP client for endpoint testing"

    func render() -> some View {
        HTTPRequestTesterView()
    }
}

struct HTTPRequestTesterView: View {
    @StateObject private var viewModel = HTTPRequestTesterViewModel()
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "HTTP Request Tester",
                description: "Configure and execute HTTP requests with detailed analytics.",
                icon: "network"
            )
            .padding()

            Picker("Mode", selection: $selectedTab) {
                Text("Request").tag(0)
                Text("Headers").tag(1)
                Text("Auth").tag(2)
                Text("Response").tag(3)
                Text("History").tag(4)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            TabView(selection: $selectedTab) {
                requestTab.tag(0)
                headersTab.tag(1)
                authTab.tag(2)
                responseTab.tag(3)
                historyTab.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var requestTab: some View {
        Form {
            Section("Endpoint") {
                HStack {
                    Picker("Method", selection: $viewModel.method) {
                        ForEach(["GET", "POST", "PUT", "PATCH", "DELETE"], id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                    .frame(width: 100)

                    TextField("https://api.example.com", text: $viewModel.url)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }

            Section("Body") {
                TextEditor(text: $viewModel.body)
                    .frame(height: 150)
                    .font(.system(.caption, design: .monospaced))
            }

            Button {
                Task { await viewModel.send() }
                selectedTab = 3
            } label: {
                if viewModel.isLoading {
                    ProgressView().padding(.trailing, 8)
                }
                Text("Send Request")
            }
            .disabled(viewModel.isLoading || viewModel.url.isEmpty)
        }
    }

    private var headersTab: some View {
        List {
            ForEach($viewModel.headers) { $header in
                HStack {
                    TextField("Key", text: $header.key)
                    TextField("Value", text: $header.value)
                }
            }
            .onDelete { viewModel.headers.remove(atOffsets: $0) }

            Button("Add Header") {
                viewModel.headers.append(HTTPHeader(key: "", value: ""))
            }
        }
    }

    private var authTab: some View {
        Form {
            Picker("Auth Type", selection: $viewModel.authType) {
                Text("None").tag(AuthType.none)
                Text("Bearer Token").tag(AuthType.bearer)
                Text("API Key").tag(AuthType.apiKey)
            }

            if viewModel.authType == .bearer {
                SecureField("Token", text: $viewModel.authToken)
            } else if viewModel.authType == .apiKey {
                TextField("Key Name", text: $viewModel.apiKeyName)
                SecureField("Key Value", text: $viewModel.apiKeyValue)
            }
        }
    }

    private var responseTab: some View {
        VStack {
            if let response = viewModel.lastResponse {
                List {
                    Section("Status") {
                        HStack {
                            StatusBadge(text: "\(response.statusCode)", color: response.statusCode < 400 ? .green : .red)
                            Text(response.statusDescription)
                            Spacer()
                            Text("\(Int(response.duration * 1000))ms")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Response Headers") {
                        ForEach(response.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            LabeledContent(key, value: value)
                        }
                    }

                    Section("Body") {
                        JSONView(json: response.body)
                            .frame(minHeight: 200)
                    }
                }
            } else {
                ContentUnavailableView("No Response", systemImage: "arrow.up.circle", description: Text("Execute a request to see the results."))
            }
        }
    }

    private var historyTab: some View {
        HistoryView(history: viewModel.history) { item in
            viewModel.loadHistory(item)
            selectedTab = 0
        } onClear: {
            viewModel.history.removeAll()
        }
    }
}

class HTTPRequestTesterViewModel: ObservableObject {
    @Published var url = "https://api.github.com/zen"
    @Published var method = "GET"
    @Published var body = ""
    @Published var headers: [HTTPHeader] = [HTTPHeader(key: "Content-Type", value: "application/json")]
    @Published var authType = AuthType.none
    @Published var authToken = ""
    @Published var apiKeyName = ""
    @Published var apiKeyValue = ""

    @Published var isLoading = false
    @Published var lastResponse: HTTPResponse?
    @Published var history: [HistoryItem] = []

    func send() async {
        guard let urlObj = URL(string: url) else { return }

        await MainActor.run { isLoading = true }
        let startTime = Date()

        var request = URLRequest(url: urlObj)
        request.httpMethod = method

        for header in headers where !header.key.isEmpty {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }

        switch authType {
        case .bearer:
            request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        case .apiKey:
            request.addValue(apiKeyValue, forHTTPHeaderField: apiKeyName)
        case .none: break
        }

        if !body.isEmpty && method != "GET" {
            request.httpBody = body.data(using: .utf8)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            let httpResponse = response as? HTTPURLResponse
            let bodyString = String(data: data, encoding: .utf8) ?? "Binary Data"

            await MainActor.run {
                self.lastResponse = HTTPResponse(
                    statusCode: httpResponse?.statusCode ?? 0,
                    statusDescription: HTTPURLResponse.localizedString(forStatusCode: httpResponse?.statusCode ?? 0),
                    headers: (httpResponse?.allHeaderFields as? [String: String]) ?? [:],
                    body: bodyString,
                    duration: duration
                )
                self.history.insert(HistoryItem(title: "\(method) \(url)", detail: "Status: \(self.lastResponse?.statusCode ?? 0)"), at: 0)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.lastResponse = HTTPResponse(statusCode: 0, statusDescription: error.localizedDescription, headers: [:], body: "", duration: 0)
                self.isLoading = false
            }
        }
    }

    func loadHistory(_ item: HistoryItem) {
        // Simple loading logic - in a real app we'd store the full request in HistoryItem
        if let firstSpace = item.title.firstIndex(of: " ") {
            self.method = String(item.title[..<firstSpace])
            self.url = String(item.title[item.title.index(after: firstSpace)...])
        }
    }
}

struct HTTPHeader: Identifiable, Codable {
    let id = UUID()
    var key: String
    var value: String
}

struct HTTPResponse {
    let statusCode: Int
    let statusDescription: String
    let headers: [String: String]
    let body: String
    let duration: TimeInterval
}

enum AuthType: String, Codable {
    case none, bearer, apiKey
}
