import SwiftUI

struct HTTPInspectorView: View {
    @StateObject private var backend = HTTPInspectorBackend()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Enter URL (e.g., https://apple.com)", text: $backend.url)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Button(action: backend.inspect) {
                    if backend.isLoading {
                        ProgressView()
                    } else {
                        Text("Inspect")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isLoading || backend.url.isEmpty)
            }

            if !backend.error.isEmpty {
                Text(backend.error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if !backend.responseHeaders.isEmpty {
                List {
                    ForEach(backend.responseHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(value)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            } else if !backend.isLoading {
                ContentUnavailableView("No Headers", systemImage: "network.badge.shield.half.filled", description: Text("Enter a URL to inspect its HTTP response headers."))
            }
        }
        .padding()
        .navigationTitle("HTTP Inspector")
    }
}

struct HTTPInspectorTool: Tool, Sendable {
    let name = "HTTP Inspector"
    let icon = "network.badge.shield.half.filled"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Inspect HTTP response headers for any URL"
    let requiresAPI = true
    var view: AnyView { AnyView(HTTPInspectorView()) }
}
