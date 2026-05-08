import SwiftUI

struct ConnectorTestConsoleView: View {
    @State var connector: ConnectorDefinition
    @Environment(\.dismiss) var dismiss

    @State private var selectedEndpointID: UUID?
    @State private var requestBody = "{}"
    @State private var responseOutput = "No data yet."
    @State private var isExecuting = false
    @State private var statusCode: Int?
    @State private var responseTime: TimeInterval?
    @State private var requestHistory: [TestRequest] = []
    @State private var selectedTab = 0
    @State private var customHeaders: [HeaderEntry] = []
    @State private var showingCurlExport = false
    @State private var curlCommand = ""
    @State private var responseContentType = ""

    struct TestRequest: Identifiable {
        let id = UUID()
        let endpoint: String
        let method: String
        let statusCode: Int?
        let responseTime: TimeInterval?
        let timestamp: Date
        let response: String
    }

    struct HeaderEntry: Identifiable {
        let id = UUID()
        var key: String
        var value: String
    }

    var selectedEndpoint: ConnectorEndpoint? {
        guard let id = selectedEndpointID else { return nil }
        return connector.endpoints.first(where: { $0.id == id })
    }

    var body: some View {
        List {
            // MARK: - Endpoint Selector
            Section {
                Picker("Endpoint", selection: $selectedEndpointID) {
                    Text("Select Endpoint").tag(Optional<UUID>.none)
                    ForEach(connector.endpoints) { ep in
                        HStack {
                            Text(ep.method)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                            Text(ep.path)
                                .font(.system(.caption, design: .monospaced))
                        }
                        .tag(Optional(ep.id))
                    }
                }

                if connector.endpoints.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("No endpoints configured. Add endpoints in the Builder.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                if let ep = selectedEndpoint {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(ep.method)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(methodColor(ep.method).opacity(0.15))
                                .foregroundColor(methodColor(ep.method))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text(ep.path)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(2)
                        }
                        if !ep.headers.isEmpty {
                            Text("\(ep.headers.count) default headers configured")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("API Simulation")
            }

            // MARK: - Request Configuration
            Picker("Tab", selection: $selectedTab) {
                Text("Body").tag(0)
                Text("Headers").tag(1)
                Text("History").tag(2)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            switch selectedTab {
            case 0: requestBodySection
            case 1: headersSection
            case 2: historySection
            default: requestBodySection
            }

            // MARK: - Execute Button
            Section {
                Button(action: runTest) {
                    if isExecuting {
                        HStack {
                            ProgressView()
                            Text("Executing...")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Send Request")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .disabled(isExecuting || selectedEndpointID == nil)
            }

            // MARK: - Response Console
            Section {
                if let code = statusCode {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text("\(code)")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(code < 300 ? .green : (code < 400 ? .orange : .red))
                            .bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background((code < 300 ? Color.green : (code < 400 ? Color.orange : Color.red)).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                if let time = responseTime {
                    HStack {
                        Text("Response Time")
                        Spacer()
                        Text(String(format: "%.0fms", time * 1000))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(time < 1.0 ? .green : (time < 3.0 ? .orange : .red))
                    }
                }

                if !responseContentType.isEmpty {
                    HStack {
                        Text("Content-Type")
                        Spacer()
                        Text(responseContentType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                ScrollView {
                    Text(responseOutput)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 200)
                .background(Color.black.opacity(0.05))
                .cornerRadius(8)

                // Response Actions
                if statusCode != nil {
                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = responseOutput
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button {
                            generateCurlCommand()
                            showingCurlExport = true
                        } label: {
                            Label("cURL", systemImage: "terminal")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Spacer()

                        Button {
                            clearResponse()
                        } label: {
                            Label("Clear", systemImage: "xmark.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            } header: {
                Text("Response Console")
            }
        }
        .navigationTitle("Test Console")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showingCurlExport) {
            curlExportSheet
        }
    }

    // MARK: - Request Body

    private var requestBodySection: some View {
        Section {
            TextEditor(text: $requestBody)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 150)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))

            HStack {
                Button {
                    formatRequestBody()
                } label: {
                    Label("Format", systemImage: "text.alignleft")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Text("\(requestBody.count) chars")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Request Body")
        }
    }

    // MARK: - Headers

    private var headersSection: some View {
        Section {
            if customHeaders.isEmpty {
                Text("No custom headers. Default headers from endpoint configuration will be used.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach($customHeaders) { $header in
                    HStack {
                        TextField("Header Name", text: $header.key)
                            .font(.system(.caption, design: .monospaced))
                        Text(":")
                            .foregroundColor(.secondary)
                        TextField("Value", text: $header.value)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                .onDelete { indices in
                    customHeaders.remove(atOffsets: indices)
                }
            }

            Button {
                customHeaders.append(HeaderEntry(key: "", value: ""))
            } label: {
                Label("Add Header", systemImage: "plus.circle")
                    .font(.caption)
            }

            // Quick-add common headers
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(["Content-Type: application/json", "Accept: application/json", "Authorization: Bearer"], id: \.self) { header in
                        Button {
                            let parts = header.split(separator: ":", maxSplits: 1)
                            if parts.count == 2 {
                                customHeaders.append(HeaderEntry(
                                    key: String(parts[0]).trimmingCharacters(in: .whitespaces),
                                    value: String(parts[1]).trimmingCharacters(in: .whitespaces)
                                ))
                            }
                        } label: {
                            Text(header)
                                .font(.system(size: 9, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } header: {
            Text("Custom Headers")
        }
    }

    // MARK: - History

    private var historySection: some View {
        Section {
            if requestHistory.isEmpty {
                Text("No requests made yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(requestHistory) { request in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(request.method)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(methodColor(request.method).opacity(0.15))
                                .foregroundColor(methodColor(request.method))
                                .clipShape(RoundedRectangle(cornerRadius: 3))

                            Text(request.endpoint)
                                .font(.system(.caption2, design: .monospaced))
                                .lineLimit(1)

                            Spacer()

                            if let code = request.statusCode {
                                Text("\(code)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(code < 300 ? .green : .red)
                            }
                        }

                        HStack {
                            Text(request.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            if let time = request.responseTime {
                                Text(String(format: "%.0fms", time * 1000))
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    .onTapGesture {
                        responseOutput = request.response
                        statusCode = request.statusCode
                        responseTime = request.responseTime
                    }
                }

                Button(role: .destructive) {
                    requestHistory.removeAll()
                } label: {
                    Label("Clear History", systemImage: "trash")
                        .font(.caption)
                }
            }
        } header: {
            Text("Request History")
        }
    }

    // MARK: - cURL Export

    private var curlExportSheet: some View {
        NavigationView {
            ScrollView {
                Text(curlCommand)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(8)
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle("cURL Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingCurlExport = false }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIPasteboard.general.string = curlCommand
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func runTest() {
        guard let endpointID = selectedEndpointID,
              let endpoint = connector.endpoints.first(where: { $0.id == endpointID }) else { return }

        isExecuting = true
        responseOutput = "Executing request..."
        let startTime = Date()

        Task {
            do {
                let data = try await ConnectorExecutionService.shared.execute(endpoint: endpoint, connector: connector)
                let elapsed = Date().timeIntervalSince(startTime)
                let output = String(data: data, encoding: .utf8) ?? "Invalid response data"

                await MainActor.run {
                    self.responseOutput = output
                    self.statusCode = 200
                    self.responseTime = elapsed
                    self.responseContentType = "application/json"
                    self.isExecuting = false

                    self.requestHistory.insert(TestRequest(
                        endpoint: endpoint.path,
                        method: endpoint.method,
                        statusCode: 200,
                        responseTime: elapsed,
                        timestamp: Date(),
                        response: output
                    ), at: 0)
                }
            } catch {
                let elapsed = Date().timeIntervalSince(startTime)

                await MainActor.run {
                    self.responseOutput = "Error: \(error.localizedDescription)"
                    self.statusCode = (error as NSError).code
                    self.responseTime = elapsed
                    self.isExecuting = false

                    self.requestHistory.insert(TestRequest(
                        endpoint: endpoint.path,
                        method: endpoint.method,
                        statusCode: (error as NSError).code,
                        responseTime: elapsed,
                        timestamp: Date(),
                        response: "Error: \(error.localizedDescription)"
                    ), at: 0)
                }
            }
        }
    }

    private func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .secondary
        }
    }

    private func formatRequestBody() {
        guard let data = requestBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let result = String(data: formatted, encoding: .utf8) else { return }
        requestBody = result
    }

    private func clearResponse() {
        responseOutput = "No data yet."
        statusCode = nil
        responseTime = nil
        responseContentType = ""
    }

    private func generateCurlCommand() {
        guard let endpoint = selectedEndpoint else { return }

        var cmd = "curl -X \(endpoint.method) \\\n  '\(endpoint.path)'"

        for header in customHeaders where !header.key.isEmpty {
            cmd += " \\\n  -H '\(header.key): \(header.value)'"
        }

        for (key, value) in endpoint.headers {
            cmd += " \\\n  -H '\(key): \(value)'"
        }

        if endpoint.method != "GET" && !requestBody.isEmpty && requestBody != "{}" {
            cmd += " \\\n  -d '\(requestBody)'"
        }

        curlCommand = cmd
    }
}
