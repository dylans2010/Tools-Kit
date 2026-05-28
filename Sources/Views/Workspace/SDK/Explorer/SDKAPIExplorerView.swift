import SwiftUI

struct SDKAPIExplorerView: View {
    @State private var searchText = ""
    @State private var selectedModule = "All"
    @State private var testPath = ""
    @State private var testMethod: SDKRoute.Method = .get
    @State private var testParams: String = ""
    @State private var testResult: SDKResponse?
    @State private var isTesting = false
    @State private var requestHistory: [RequestHistoryEntry] = []
    @State private var showingHistory = false
    @State private var showingHeaders = false
    @State private var customHeaders: [CustomHeader] = []
    @State private var showingEnvironments = false
    @State private var environments: [APIEnvironment] = [
        APIEnvironment(name: "Development", baseURL: "http://localhost:8080"),
        APIEnvironment(name: "Staging", baseURL: "https://staging.api.example.com"),
        APIEnvironment(name: "Production", baseURL: "https://api.example.com")
    ]
    @State private var selectedEnvironment = 0
    @State private var showingSavedRequests = false
    @State private var savedRequests: [SavedRequest] = []
    @State private var requestBody = ""
    @State private var showingBodyEditor = false
    @State private var responseTime: Double = 0
    @State private var showingCurlExport = false
    @State private var curlCommand = ""
    @State private var filterByMethod: SDKRoute.Method?

    private var modules: [String] {
        var mods = Set(SDKRouter.shared.routes().map { $0.module })
        mods.insert("All")
        return mods.sorted()
    }

    private var filteredRoutes: [SDKRoute] {
        SDKRouter.shared.routes().filter { route in
            let matchesModule = selectedModule == "All" || route.module == selectedModule
            let matchesSearch = searchText.isEmpty ||
                route.path.localizedCaseInsensitiveContains(searchText) ||
                route.method.rawValue.localizedCaseInsensitiveContains(searchText)
            let matchesMethod = filterByMethod == nil || route.method == filterByMethod
            return matchesModule && matchesSearch && matchesMethod
        }
    }

    var body: some View {
        List {
            environmentSection
            methodFilterSection
            endpointsSection
            testConsoleSection
            bodyEditorSection
            headersSection
            responseSection
            historySection
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search endpoints")
        .navigationTitle("API Explorer")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Module", selection: $selectedModule) {
                        ForEach(modules, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    Divider()
                    Button { showingHistory = true } label: { Label("Request History", systemImage: "clock") }
                    Button { showingSavedRequests = true } label: { Label("Saved Requests", systemImage: "bookmark") }
                    Button { showingEnvironments = true } label: { Label("Environments", systemImage: "server.rack") }
                    if testResult != nil {
                        Divider()
                        Button { exportAsCurl() } label: { Label("Copy as cURL", systemImage: "doc.on.doc") }
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingHistory) {
            NavigationStack { requestHistorySheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSavedRequests) {
            NavigationStack { savedRequestsSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEnvironments) {
            NavigationStack { environmentsSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingCurlExport) {
            NavigationStack { curlExportSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Environment Section

    private var environmentSection: some View {
        Section {
            Picker("Environment", selection: $selectedEnvironment) {
                ForEach(Array(environments.enumerated()), id: \.offset) { idx, env in
                    Text(env.name).tag(idx)
                }
            }
            .pickerStyle(.segmented)
            if environments.indices.contains(selectedEnvironment) {
                Text(environments[selectedEnvironment].baseURL)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("API Environment", systemImage: "server.rack")
        }
    }

    // MARK: - Method Filter

    private var methodFilterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    methodFilterChip(nil, "All")
                    ForEach(SDKRoute.Method.allCases, id: \.self) { method in
                        methodFilterChip(method, method.rawValue)
                    }
                }
            }
        }
    }

    // MARK: - Endpoints Section

    private var endpointsSection: some View {
        Section {
            ForEach(filteredRoutes) { route in
                Button {
                    testPath = route.path
                    testMethod = route.method
                } label: {
                    HStack {
                        MethodBadge(method: route.method)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(route.path).font(.subheadline.monospaced())
                            Text(route.module).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let matching = requestHistory.first(where: { $0.path == route.path && $0.method == route.method }) {
                            Text("\(matching.statusCode)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(matching.statusCode < 400 ? .green : .red)
                        }
                    }
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .leading) {
                    Button {
                        savedRequests.append(SavedRequest(name: route.path, method: route.method, path: route.path, params: "", body: ""))
                    } label: {
                        Label("Save", systemImage: "bookmark")
                    }
                    .tint(.blue)
                }
            }
        } header: {
            Label("Endpoints (\(filteredRoutes.count))", systemImage: "point.3.connected.trianglepath.dotted")
        }
    }

    // MARK: - Test Console

    private var testConsoleSection: some View {
        Section {
            HStack {
                Picker("Method", selection: $testMethod) {
                    ForEach(SDKRoute.Method.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(width: 100)

                TextField("/path", text: $testPath)
                    .font(.body.monospaced())
                    .textInputAutocapitalization(.never)
            }

            TextField("Parameters (key=value&key2=value2)", text: $testParams)
                .font(.caption.monospaced())

            Button(action: executeRequest) {
                HStack {
                    if isTesting { ProgressView().controlSize(.small) }
                    Label("Execute Request", systemImage: "play.circle.fill")
                        .bold()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(testPath.isEmpty || isTesting)
        } header: {
            Label("Test Console", systemImage: "terminal.fill")
        }
    }

    // MARK: - Body Editor

    private var bodyEditorSection: some View {
        Section {
            if testMethod == .post || testMethod == .put {
                TextEditor(text: $requestBody)
                    .font(.caption.monospaced())
                    .frame(minHeight: 60)
                HStack {
                    Button("Format JSON") { formatRequestBody() }.font(.caption)
                    Spacer()
                    Text("\(requestBody.count) chars").font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                Text("Body editor available for POST/PUT methods")
                    .font(.caption).foregroundStyle(.secondary)
            }
        } header: {
            Label("Request Body", systemImage: "doc.text")
        }
    }

    // MARK: - Headers Section

    private var headersSection: some View {
        Section {
            if customHeaders.isEmpty {
                Text("No custom headers").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(customHeaders) { header in
                    HStack {
                        Text(header.key).font(.caption.monospaced())
                        Spacer()
                        Text(header.value).font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                }
                .onDelete { customHeaders.remove(atOffsets: $0) }
            }
            Button {
                customHeaders.append(CustomHeader(key: "Content-Type", value: "application/json"))
            } label: {
                Label("Add Header", systemImage: "plus.circle")
                    .font(.caption)
            }
        } header: {
            Label("Headers (\(customHeaders.count))", systemImage: "list.bullet.rectangle")
        }
    }

    // MARK: - Response Section

    private var responseSection: some View {
        Group {
            if let result = testResult {
                Section {
                    LabeledContent("Status") {
                        Text(result.status.rawValue)
                            .foregroundStyle(result.isSuccess ? Color.green : Color.red).bold()
                    }
                    LabeledContent("Latency", value: "\(Int(result.latency * 1000))ms")
                    LabeledContent("Response Size") {
                        let size = result.data.values.joined().count
                        Text("\(size) bytes").font(.caption.monospacedDigit())
                    }

                    if !result.data.isEmpty {
                        ForEach(result.data.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key).font(.caption2.bold()).foregroundStyle(.secondary)
                                Text(value).font(.caption.monospaced()).textSelection(.enabled)
                            }
                        }
                    }

                    if let error = result.error {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundStyle(.red)
                    }

                    HStack {
                        Button { exportAsCurl() } label: {
                            Label("Copy cURL", systemImage: "doc.on.doc").font(.caption)
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = result.data.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                        } label: {
                            Label("Copy Response", systemImage: "doc.on.clipboard").font(.caption)
                        }
                    }
                } header: {
                    Label("Response", systemImage: "arrow.down.doc.fill")
                }
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        Section {
            if requestHistory.isEmpty {
                Text("No requests in history").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(requestHistory.prefix(5)) { entry in
                    Button {
                        testMethod = entry.method
                        testPath = entry.path
                        testParams = entry.params
                    } label: {
                        HStack {
                            MethodBadge(method: entry.method)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(entry.path).font(.caption.monospaced())
                                Text("\(entry.statusCode) — \(entry.durationMs)ms")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Label("Recent History", systemImage: "clock")
        }
    }

    // MARK: - Sheets

    private var requestHistorySheet: some View {
        List {
            ForEach(requestHistory) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        MethodBadge(method: entry.method)
                        Text(entry.path).font(.subheadline.monospaced())
                    }
                    HStack {
                        Text("\(entry.statusCode)")
                            .foregroundStyle(entry.statusCode < 400 ? .green : .red)
                        Text("\(entry.durationMs)ms")
                        Spacer()
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption2.monospacedDigit())
                }
                .padding(.vertical, 2)
            }
            .onDelete { requestHistory.remove(atOffsets: $0) }
        }
        .navigationTitle("Request History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") { requestHistory.removeAll() }
            }
        }
    }

    private var savedRequestsSheet: some View {
        List {
            if savedRequests.isEmpty {
                ContentUnavailableView("No Saved Requests", systemImage: "bookmark.slash", description: Text("Swipe left on endpoints to save requests."))
            } else {
                ForEach(savedRequests) { req in
                    Button {
                        testMethod = req.method
                        testPath = req.path
                        testParams = req.params
                        requestBody = req.body
                        showingSavedRequests = false
                    } label: {
                        HStack {
                            MethodBadge(method: req.method)
                            VStack(alignment: .leading) {
                                Text(req.name).font(.subheadline)
                                Text(req.path).font(.caption2.monospaced()).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { savedRequests.remove(atOffsets: $0) }
            }
        }
        .navigationTitle("Saved Requests")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var environmentsSheet: some View {
        Form {
            ForEach(Array(environments.enumerated()), id: \.offset) { idx, env in
                VStack(alignment: .leading) {
                    Text(env.name).font(.subheadline.bold())
                    Text(env.baseURL).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Environments")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var curlExportSheet: some View {
        Form {
            Section(header: Text("cURL Command")) {
                Text(curlCommand)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
            Section {
                Button("Copy to Clipboard") {
                    UIPasteboard.general.string = curlCommand
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("cURL Export")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func methodFilterChip(_ method: SDKRoute.Method?, _ label: String) -> some View {
        Button {
            filterByMethod = method
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(filterByMethod == method ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(filterByMethod == method ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func executeRequest() {
        isTesting = true
        let params = parseParams(testParams)
        let request = SDKRequest(path: testPath, method: testMethod, parameters: params)
        let startTime = Date()
        Task {
            do {
                let response = try await SDKRouter.shared.handle(request)
                let duration = Date().timeIntervalSince(startTime)
                await MainActor.run {
                    testResult = response
                    responseTime = duration
                    isTesting = false
                    requestHistory.insert(RequestHistoryEntry(
                        method: testMethod,
                        path: testPath,
                        params: testParams,
                        statusCode: response.isSuccess ? 200 : 500,
                        durationMs: Int(duration * 1000),
                        timestamp: Date()
                    ), at: 0)
                    if requestHistory.count > 50 { requestHistory = Array(requestHistory.prefix(50)) }
                }
            } catch {
                await MainActor.run {
                    testResult = SDKResponse(requestId: request.id, status: .error, error: error.localizedDescription)
                    isTesting = false
                    requestHistory.insert(RequestHistoryEntry(
                        method: testMethod,
                        path: testPath,
                        params: testParams,
                        statusCode: 500,
                        durationMs: Int(Date().timeIntervalSince(startTime) * 1000),
                        timestamp: Date()
                    ), at: 0)
                }
            }
        }
    }

    private func parseParams(_ raw: String) -> [String: String] {
        guard !raw.isEmpty else { return [:] }
        var result: [String: String] = [:]
        for pair in raw.components(separatedBy: "&") {
            let parts = pair.components(separatedBy: "=")
            if parts.count == 2 { result[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces) }
        }
        return result
    }

    private func formatRequestBody() {
        guard let data = requestBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: formatted, encoding: .utf8) else { return }
        requestBody = str
    }

    private func exportAsCurl() {
        var cmd = "curl"
        if testMethod != .get { cmd += " -X \(testMethod.rawValue)" }
        let baseURL = environments.indices.contains(selectedEnvironment) ? environments[selectedEnvironment].baseURL : ""
        cmd += " '\(baseURL)\(testPath)'"
        for header in customHeaders {
            cmd += " -H '\(header.key): \(header.value)'"
        }
        if !requestBody.isEmpty && (testMethod == .post || testMethod == .put) {
            cmd += " -d '\(requestBody)'"
        }
        curlCommand = cmd
        showingCurlExport = true
    }
}

// MARK: - Private Models

private struct MethodBadge: View {
    let method: SDKRoute.Method
    var body: some View {
        Text(method.rawValue)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(color)
            .frame(width: 44)
    }
    private var color: Color {
        switch method { case .get: return .blue; case .post: return .green; case .put: return .orange; case .delete: return .red }
    }
}

private struct RequestHistoryEntry: Identifiable {
    let id = UUID()
    let method: SDKRoute.Method
    let path: String
    let params: String
    let statusCode: Int
    let durationMs: Int
    let timestamp: Date
}

private struct CustomHeader: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

private struct APIEnvironment: Identifiable {
    let id = UUID()
    let name: String
    let baseURL: String
}

private struct SavedRequest: Identifiable {
    let id = UUID()
    let name: String
    let method: SDKRoute.Method
    let path: String
    let params: String
    let body: String
}
