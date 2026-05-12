import SwiftUI

struct WebhookTesterView: View {
    @StateObject private var backend = WebhookTesterBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Webhook URL").font(.caption).foregroundColor(.secondary)
                    TextField("https://...", text: $backend.urlString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("JSON Payload").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $backend.payload)
                        .frame(height: 120)
                        .font(.system(.subheadline, design: .monospaced))
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }

                Button(action: backend.send) {
                    if backend.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Label("Send Test Webhook", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isLoading || backend.urlString.isEmpty)

                if let error = backend.error {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                if !backend.responseText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server Response").font(.headline)
                        Text(backend.responseText)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Webhook Tester")
    }
}

struct WebhookTesterTool: Tool, Sendable {
    let name = "Webhook Tester"
    let icon = "link.badge.plus"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Send and test POST webhooks with custom JSON payloads"
    let requiresAPI = true
    var view: AnyView { AnyView(WebhookTesterView()) }
}
