import SwiftUI

private enum _DTAuthType: String, CaseIterable, Hashable {
    case none
    case apiKey
    case bearer
    case basic
    case oauth2
}

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
            Picker("Mode", selection: $selectedTab) {
                Label("Req", systemImage: "paperplane").tag(0)
                Label("Head", systemImage: "list.bullet").tag(1)
                Label("Auth", systemImage: "lock").tag(2)
                Label("Res", systemImage: "arrow.down.circle").tag(3)
                Label("Hist", systemImage: "clock").tag(4)
            }
            .pickerStyle(.segmented)
            .padding()

            TabView(selection: $selectedTab) {
                requestTab.tag(0)
                headersTab.tag(1)
                authTab.tag(2)
                responseTab.tag(3)
                historyTab.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("HTTP Tester")
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
                    .pickerStyle(.menu)
                    .frame(width: 100)

                    TextField("https://api.example.com", text: $viewModel.url)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.system(.caption, design: .monospaced))
                }
            }

            Section("Body") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.body)
                        .frame(minHeight: 180)
                        .font(.system(.caption, design: .monospaced))

                    if !viewModel.body.isEmpty {
                        Button { viewModel.body = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }
            }

            Section {
                Button {
                    Task { await viewModel.send() }
                    selectedTab = 3
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().padding(.trailing, 8)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text("Send Request")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || viewModel.url.isEmpty)
            }
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
                viewModel.headers.append(HTTPRequestHeader(key: "", value: ""))
            }
        }
    }

    private var authTab: some View {
        Form {
            Picker("Auth Type", selection: $viewModel.authType) {
                Text("None").tag(_DTAuthType.none)
                Text("Bearer Token").tag(_DTAuthType.bearer)
                Text("API Key").tag(_DTAuthType.apiKey)
                Text("Basic").tag(_DTAuthType.basic)
                Text("OAuth2").tag(_DTAuthType.oauth2)
            }

            if viewModel.authType == .bearer {
                SecureField("Token", text: $viewModel.authToken)
            } else if viewModel.authType == .apiKey {
                TextField("Key Name", text: $viewModel.apiKeyName)
                SecureField("Key Value", text: $viewModel.apiKeyValue)
            } else if viewModel.authType == .basic {
                TextField("Username", text: $viewModel.apiKeyName)
                SecureField("Password", text: $viewModel.apiKeyValue)
            }
        }
    }

    private var responseTab: some View {
        VStack {
            if let response = viewModel.lastResponse {
                List {
                    Section("Status") {
                        HStack(spacing: 16) {
                            Text("\(response.statusCode)")
                                .font(.title2.bold().monospacedDigit())
                                .foregroundStyle(response.statusCode < 400 ? .green : .red)

                            VStack(alignment: .leading) {
                                Text(response.statusDescription).font(.subheadline.bold())
                                Text("\(Int(response.duration * 1000))ms duration").font(.caption2).foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                UIPasteboard.general.string = response.body
                            } label: {
                                Label("Copy Body", systemImage: "doc.on.doc")
                                    .font(.caption2)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Response Headers (\(response.headers.count))") {
                        ForEach(response.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key).font(.caption2.bold()).foregroundStyle(.secondary)
                                Text(value).font(.system(size: 10, design: .monospaced))
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    Section("Body") {
                        ScrollView {
                            Text(response.body)
                                .font(.system(size: 11, design: .monospaced))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .frame(minHeight: 250)
                    }
                }
            } else {
                ContentUnavailableView("Ready", systemImage: "paperplane.circle", description: Text("Configure and send a request to view the response."))
            }
        }
    }

    private var historyTab: some View {
        Section {
            HStack {
                Text("History")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    viewModel.history.removeAll()
                }
                .font(.caption)
                .disabled(viewModel.history.isEmpty)
            }
            .padding(.horizontal)

            if viewModel.history.isEmpty {
                ContentUnavailableView("No History", systemImage: "clock", description: Text("Your activity will appear here."))
                    .frame(height: 200)
            } else {
                List {
                    ForEach(viewModel.history) { item in
                        Button {
                            viewModel.loadHistory(item)
                            selectedTab = 0
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                Text(item.detail)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                                Text(item.timestamp, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: 300)
            }
        }
    }
}

class HTTPRequestTesterViewModel: ObservableObject {
    @Published var url = "https://api.github.com/zen"
    @Published var method = "GET"
    @Published var body = ""
    @Published var headers: [HTTPRequestHeader] = [HTTPRequestHeader(key: "Content-Type", value: "application/json")]
    @Published fileprivate var authType = _DTAuthType.none
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
        case .basic:
            let authString = "\(apiKeyName):\(apiKeyValue)"
            if let authData = authString.data(using: .utf8) {
                let base64Auth = authData.base64EncodedString()
                request.addValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
            }
        case .none, .oauth2: break
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

struct HTTPRequestHeader: Identifiable, Codable {
    var id = UUID()
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

#Preview {
    HTTPRequestTesterView()
}
