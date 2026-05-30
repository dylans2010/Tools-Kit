import SwiftUI

struct HTTPRequestBuilderView: View {
    @State private var method = "GET"
    @State private var url = "https://api.example.com/v1/resource"
    @State private var headers: [HTTPHeader] = [HTTPHeader(key: "Content-Type", value: "application/json")]
    @State private var bodyText = "{\n  \"key\": \"value\"\n}"

    struct HTTPHeader: Identifiable {
        let id = UUID()
        var key: String
        var value: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Picker("Method", selection: $method) {
                            Text("GET").tag("GET")
                            Text("POST").tag("POST")
                            Text("PUT").tag("PUT")
                            Text("DELETE").tag("DELETE")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)

                        TextField("URL", text: $url)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Headers").font(.headline)
                        Spacer()
                        Button { headers.append(HTTPHeader(key: "", value: "")) } label: { Image(systemName: "plus.circle") }
                    }

                    ForEach($headers) { $header in
                        HStack {
                            TextField("Key", text: $header.key)
                            TextField("Value", text: $header.value)
                            Button { headers.removeAll { $0.id == header.id } } label: { Image(systemName: "minus.circle").foregroundStyle(.red) }
                        }
                        .font(.caption)
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if method != "GET" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Body").font(.headline)
                        TextEditor(text: $bodyText)
                            .font(.system(.caption, design: .monospaced))
                            .frame(height: 150)
                            .padding(4)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("CURL Preview").font(.headline)
                    Text(generateCurl())
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
        .navigationTitle("Request Builder")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func generateCurl() -> String {
        var curl = "curl -X \(method) \"\(url)\""
        for header in headers where !header.key.isEmpty {
            curl += " \\\n  -H \"\(header.key): \(header.value)\""
        }
        if method != "GET" && !bodyText.isEmpty {
            curl += " \\\n  -d '\(bodyText)'"
        }
        return curl
    }
}
