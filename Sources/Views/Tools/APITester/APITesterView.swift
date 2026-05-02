import SwiftUI

struct APITesterView: View {
    @StateObject private var backend = APITesterBackend()
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("URL", text: $backend.url)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.caption)

                    Picker("Method", selection: $backend.method) {
                        ForEach(backend.methods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Request")
                }

                Section {
                    ForEach($backend.headers) { $header in
                        HStack {
                            TextField("Key", text: $header.key)
                                .font(.caption.monospaced())
                            Divider()
                            TextField("Value", text: $header.value)
                                .font(.caption.monospaced())
                        }
                    }
                    .onDelete(perform: backend.removeHeader)

                    Button(action: backend.addHeader) {
                        Label("Add Header", systemImage: "plus.circle")
                    }
                } header: {
                    headerSectionHeader
                }

                if backend.method != "GET" && backend.method != "HEAD" {
                    Section {
                        TextEditor(text: $backend.requestBody)
                            .frame(height: 100)
                            .font(.system(.caption, design: .monospaced))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
                    } header: {
                        Text("Body")
                    }
                }

                Section {
                    Button(action: backend.sendRequest) {
                        if backend.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send Request").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backend.isLoading)
                }

                Section {
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 10, height: 10)
                        Text("Status Code: \(backend.responseStatus)")
                            .bold()
                    }
                } header: {
                    Text("Response Status")
                }

                Section {
                    if selectedTab == 0 {
                        TextEditor(text: .constant(backend.responseBody))
                            .frame(height: 250)
                            .font(.system(.caption, design: .monospaced))
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(backend.responseHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                VStack(alignment: .leading) {
                                    Text(key).font(.caption).bold()
                                    Text(value).font(.caption2).foregroundColor(.secondary)
                                }
                                Divider()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    responseTabPicker
                }
            }
        }
        .navigationTitle("API Tester")
    }

    private var headerSectionHeader: some View {
        HStack {
            Text("Headers")
            Spacer()
            EditButton().font(.caption)
        }
    }

    private var responseTabPicker: some View {
        Picker("Response Part", selection: $selectedTab) {
            Text("Body").tag(0)
            Text("Headers").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch backend.responseStatus {
        case 200...299: return .green
        case 400...499: return .orange
        case 500...599: return .red
        default: return .secondary
        }
    }
}

struct APITesterTool: Tool {
    let name = "API Tester"
    let icon = "network"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Test API endpoints with custom headers and payloads"
    let requiresAPI = true
    var view: AnyView { AnyView(APITesterView()) }
}
