import SwiftUI

struct EndpointTesterTool: Tool {
    let name = "Endpoint Tester"
    let icon = "arrow.triangle.2.circlepath.circle.fill"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Test API endpoints with custom headers, methods, and body"
    let requiresAPI = false
    var view: AnyView { AnyView(EndpointTesterView()) }
}

struct EndpointTesterView: View {
    @StateObject private var backend = EndpointTesterBackend()

    var body: some View {
        ToolDetailView(tool: EndpointTesterTool()) {
            VStack(spacing: 16) {
                requestSection
                if backend.isLoading {
                    ProgressView("Sending request…")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground)).cornerRadius(12)
                }
                if !backend.errorMessage.isEmpty {
                    errorCard
                }
                if let response = backend.response {
                    responseSection(response)
                }
                if !backend.curlCommand.isEmpty {
                    curlSection
                }
            }
        }
        .navigationTitle("Endpoint Tester")
    }

    private var requestSection: some View {
        ToolInputSection("Request") {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Picker("Method", selection: $backend.method) {
                        ForEach(backend.methods, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .padding(.leading)

                    TextField("https://…", text: $backend.urlString)
                        .autocapitalization(.none).disableAutocorrection(true)
                        .keyboardType(.URL)
                        .padding(.trailing)
                }
                .padding(.vertical, 10)

                Divider()

                VStack(alignment: .leading, spacing: 0) {
                    Text("HEADERS").font(.caption.bold()).foregroundColor(.secondary)
                        .padding(.horizontal).padding(.top, 10)
                    ForEach($backend.headers) { $header in
                        HStack {
                            TextField("Key", text: $header.key)
                                .font(.system(.caption, design: .monospaced))
                            Text(":").foregroundColor(.secondary)
                            TextField("Value", text: $header.value)
                                .font(.system(.caption, design: .monospaced))
                        }
                        .padding(.horizontal).padding(.vertical, 6)
                        Divider().padding(.leading)
                    }
                    Button {
                        backend.addHeader()
                    } label: {
                        Label("Add Header", systemImage: "plus")
                            .font(.caption).foregroundColor(.blue)
                    }
                    .padding(.horizontal).padding(.vertical, 8)
                }

                if backend.method != "GET" && backend.method != "HEAD" {
                    Divider()
                    VStack(alignment: .leading) {
                        Text("BODY").font(.caption.bold()).foregroundColor(.secondary)
                            .padding(.horizontal).padding(.top, 10)
                        TextEditor(text: $backend.requestBody)
                            .font(.system(.caption, design: .monospaced))
                            .frame(height: 100)
                            .padding(.horizontal)
                    }
                }

                Divider()

                Button {
                    Task { await backend.send() }
                } label: {
                    Label("Send Request", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isLoading)
                .padding()
            }
        }
    }

    private var errorCard: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
            Text(backend.errorMessage).font(.subheadline)
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1)).cornerRadius(12)
    }

    private func responseSection(_ response: EndpointResponse) -> some View {
        ToolInputSection("Response") {
            VStack(spacing: 0) {
                HStack {
                    statusBadge(response.statusCode)
                    Spacer()
                    Text("\(response.durationMs)ms")
                        .font(.caption.bold()).foregroundColor(.secondary)
                    Text("·").foregroundColor(.secondary)
                    Text(formattedSize(response.size))
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding()
                Divider()
                ScrollView(.horizontal) {
                    Text(response.body)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
            }
        }
    }

    private var curlSection: some View {
        ToolInputSection("cURL Command") {
            ScrollView(.horizontal) {
                Text(backend.curlCommand)
                    .font(.system(.caption2, design: .monospaced))
                    .padding()
            }
        }
    }

    private func statusBadge(_ code: Int) -> some View {
        let color: Color = code < 300 ? .green : code < 400 ? .orange : .red
        return Text("HTTP \(code)")
            .font(.caption.bold())
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }

    private func formattedSize(_ bytes: Int) -> String {
        if bytes >= 1_048_576 { return String(format: "%.1f MB", Double(bytes) / 1_048_576) }
        if bytes >= 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return "\(bytes) B"
    }
}
