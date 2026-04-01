import SwiftUI

struct APITesterView: View {
    @StateObject private var backend = APITesterBackend()

    var body: some View {
        Form {
            Section(header: Text("Request Details")) {
                TextField("URL", text: $backend.url)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Picker("Method", selection: $backend.method) {
                    ForEach(backend.methods, id: \.self) { method in
                        Text(method).tag(method)
                    }
                }
                .pickerStyle(.segmented)
            }

            if backend.method != "GET" {
                Section(header: Text("Request Body (JSON)")) {
                    TextEditor(text: $backend.requestBody)
                        .frame(height: 150)
                        .font(.system(.caption, design: .monospaced))
                }
            }

            Section {
                Button("Send Request") {
                    backend.sendRequest()
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isLoading)
            }

            Section(header: Text("Response Viewer")) {
                if backend.isLoading {
                    ProgressView("Loading...")
                } else {
                    HStack {
                        Text("Status:")
                        Text("\(backend.responseStatus)")
                            .foregroundColor(statusColor)
                            .bold()
                    }

                    TextEditor(text: .constant(backend.responseBody))
                        .frame(height: 300)
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
        .navigationTitle("API Tester")
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
    let description = "Test API endpoints with custom payloads"

    var view: AnyView {
        AnyView(APITesterView())
    }
}
