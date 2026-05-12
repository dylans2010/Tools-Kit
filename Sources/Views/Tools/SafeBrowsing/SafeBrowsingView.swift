import SwiftUI

struct SafeBrowsingTool: Tool, Sendable {
    let name = "Safe Browsing"
    let icon = "shield.lefthalf.filled"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Check URLs for threats using heuristic analysis and remote verification before opening"
    let requiresAPI = false
    var view: AnyView { AnyView(SafeBrowsingView()) }
}

struct SafeBrowsingView: View {
    @StateObject private var backend = SafeBrowsingBackend()

    var body: some View {
        ToolDetailView(tool: SafeBrowsingTool()) {
            VStack(spacing: 16) {
                inputSection
                if backend.isChecking { ProgressView("Checking URL…").padding() }
                if let result = backend.result { resultSection(result) }
                if !backend.errorMessage.isEmpty {
                    Text(backend.errorMessage).foregroundColor(.red).font(.caption).padding(.horizontal)
                }
                if !backend.history.isEmpty { historySection }
            }
        }
        .navigationTitle("Safe Browsing")
    }

    private var inputSection: some View {
        ToolInputSection("URL to Check") {
            VStack(spacing: 10) {
                TextField("https://example.com", text: $backend.urlInput)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                HStack {
                    Button("Check") { backend.check() }
                        .buttonStyle(.borderedProminent)
                        .disabled(backend.urlInput.isEmpty || backend.isChecking)
                    Button("Clear") { backend.clear() }
                        .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    private func resultSection(_ result: ThreatResult) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: result.isSafe ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundColor(result.isSafe ? .green : .red)
                    .font(.title)
                VStack(alignment: .leading) {
                    Text(result.isSafe ? "URL Appears Safe" : "Potential Threat Detected")
                        .font(.headline)
                    if !result.threatType.isEmpty {
                        Text("Threat: \(result.threatType)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    if !result.detail.isEmpty {
                        Text(result.detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background((result.isSafe ? Color.green : Color.red).opacity(0.08))
            .cornerRadius(12)
            .padding(.horizontal)

            HStack {
                Text("Source: \(result.source)").font(.caption2).foregroundColor(.secondary)
                Spacer()
                Text(result.checkedAt, style: .time).font(.caption2).foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }

    private var historySection: some View {
        ToolInputSection("History") {
            ForEach(backend.history.prefix(10), id: \.url) { item in
                HStack {
                    Image(systemName: item.isSafe ? "checkmark.circle" : "xmark.circle")
                        .foregroundColor(item.isSafe ? .green : .red)
                    Text(item.url).font(.caption).lineLimit(1)
                    Spacer()
                    Text(item.checkedAt, style: .time).font(.caption2).foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                Divider()
            }
        }
    }
}
