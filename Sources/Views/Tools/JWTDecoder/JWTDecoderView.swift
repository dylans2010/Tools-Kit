import SwiftUI

struct JWTDecoderView: View {
    @StateObject private var backend = JWTDecoderBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("JWT Token").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $backend.token)
                        .frame(height: 100)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }

                Button(action: { backend.decode() }) {
                    Text("Decode JWT")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if !backend.error.isEmpty {
                    Text(backend.error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if !backend.header.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Header").font(.headline)
                        Text(backend.header)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }

                if !backend.payload.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Payload").font(.headline)
                        Text(backend.payload)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("JWT Decoder")
    }
}

struct JWTDecoderTool: Tool {
    let name = "JWT Decoder"
    let icon = "key.fill"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Decode JWT tokens"
    let requiresAPI = false
    var view: AnyView { AnyView(JWTDecoderView()) }
}
