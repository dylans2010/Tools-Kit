import SwiftUI

struct HeaderInspectorDevTool: DevTool {
    let id = "header-inspector"
    let name = "Header Inspector"
    let category = DevToolCategory.networking
    let icon = "list.bullet.indent"
    let description = "Inspect and analyze HTTP headers"

    func render() -> some View {
        HeaderInspectorView()
    }
}

struct HeaderInspectorView: View {
    @StateObject private var viewModel = HeaderInspectorViewModel()
    @State private var rawHeaders = "Content-Type: application/json\nCache-Control: no-cache\nStrict-Transport-Security: max-age=31536000"

    var body: some View {
        List {
            Section("Source") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $rawHeaders)
                        .frame(height: 150)
                        .font(.system(.caption, design: .monospaced))
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    if !rawHeaders.isEmpty {
                        Button { rawHeaders = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }

                Button {
                    viewModel.analyze(rawHeaders)
                } label: {
                    Label("Analyze Security & Performance", systemImage: "magnifyingglass.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(rawHeaders.isEmpty)
            }

            if !viewModel.headers.isEmpty {
                Section("Security Score: \(viewModel.securityScore)%") {
                    ProgressView(value: Double(viewModel.securityScore) / 100)
                        .tint(viewModel.securityScore > 70 ? .green : (viewModel.securityScore > 40 ? .orange : .red))

                    ForEach(viewModel.analysisResults) { result in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: result.isPositive ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                .foregroundStyle(result.isPositive ? .green : .red)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title).font(.subheadline.bold())
                                Text(result.description).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Parsed Dictionary (\(viewModel.headers.count))") {
                    ForEach(viewModel.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(key).font(.system(size: 8, weight: .black)).foregroundStyle(.blue)
                                Spacer()
                                Button { UIPasteboard.general.string = value } label: {
                                    Image(systemName: "doc.on.doc").font(.system(size: 8))
                                }
                            }
                            Text(value)
                                .font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Header Inspector")
        .onAppear { if viewModel.headers.isEmpty { viewModel.analyze(rawHeaders) } }
    }
}

struct HeaderAnalysisResult: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let isPositive: Bool
}

class HeaderInspectorViewModel: ObservableObject {
    @Published var headers: [String: String] = [:]
    @Published var analysisResults: [HeaderAnalysisResult] = []
    @Published var securityScore = 0

    func analyze(_ raw: String) {
        headers = [:]
        analysisResults = []
        var score = 0

        let lines = raw.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                headers[parts[0]] = parts[1]
            }
        }

        // Basic Security Analysis
        if checkHeader("Strict-Transport-Security", positiveDesc: "HSTS is active. Secure transport is enforced.", negativeDesc: "HSTS is missing. Vulnerable to MITM attacks.") { score += 33 }
        if checkHeader("Content-Security-Policy", positiveDesc: "CSP is defined. XSS protection is configured.", negativeDesc: "CSP is missing. Critical XSS risk.") { score += 34 }
        if checkHeader("X-Content-Type-Options", positiveDesc: "MIME sniffing is blocked.", negativeDesc: "MIME sniffing is allowed. Possible script injection.") { score += 33 }

        self.securityScore = score

        if let cache = headers["Cache-Control"] {
            analysisResults.append(HeaderAnalysisResult(title: "Cache Policy", description: "Found: \(cache)", isPositive: true))
        }
    }

    private func checkHeader(_ key: String, positiveDesc: String, negativeDesc: String) -> Bool {
        if let _ = headers.keys.first(where: { $0.lowercased() == key.lowercased() }) {
            analysisResults.append(HeaderAnalysisResult(title: key, description: positiveDesc, isPositive: true))
            return true
        } else {
            analysisResults.append(HeaderAnalysisResult(title: key, description: negativeDesc, isPositive: false))
            return false
        }
    }
}

#Preview {
    HeaderInspectorView()
}
