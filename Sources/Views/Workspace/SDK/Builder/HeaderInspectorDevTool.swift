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
    @State private var rawHeaders = ""

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Header Inspector",
                description: "Paste raw HTTP headers to parse and analyze security and caching policies.",
                icon: "list.bullet.indent"
            )
            .padding()

            Form {
                Section("Input Raw Headers") {
                    TextEditor(text: $rawHeaders)
                        .frame(height: 150)
                        .font(.system(.caption, design: .monospaced))

                    Button("Analyze Headers") {
                        viewModel.analyze(rawHeaders)
                    }
                    .disabled(rawHeaders.isEmpty)
                }

                if !viewModel.headers.isEmpty {
                    Section("Analysis") {
                        ForEach(viewModel.analysisResults) { result in
                            HStack {
                                Image(systemName: result.isPositive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(result.isPositive ? .green : .orange)
                                VStack(alignment: .leading) {
                                    Text(result.title).font(.subheadline.bold())
                                    Text(result.description).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section("Parsed Headers") {
                        ForEach(viewModel.headers, id: \.key) { header in
                            VStack(alignment: .leading) {
                                Text(header.key).font(.caption.bold()).foregroundStyle(.accent)
                                Text(header.value).font(.caption2).textSelection(.enabled)
                            }
                        }
                    }
                }
            }
        }
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

    func analyze(_ raw: String) {
        headers = [:]
        analysisResults = []

        let lines = raw.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                headers[parts[0]] = parts[1]
            }
        }

        // Basic Security Analysis
        checkHeader("Strict-Transport-Security", positiveDesc: "HSTS is enabled.", negativeDesc: "HSTS is missing. Risk of man-in-the-middle attacks.")
        checkHeader("Content-Security-Policy", positiveDesc: "CSP is defined.", negativeDesc: "CSP is missing. Risk of XSS attacks.")
        checkHeader("X-Content-Type-Options", positiveDesc: "MIME sniffing is disabled.", negativeDesc: "MIME sniffing might be enabled.")

        // Caching Analysis
        if let cache = headers["Cache-Control"] {
            analysisResults.append(HeaderAnalysisResult(title: "Cache Policy", description: "Found: \(cache)", isPositive: true))
        }
    }

    private func checkHeader(_ key: String, positiveDesc: String, negativeDesc: String) {
        if headers[key] != nil {
            analysisResults.append(HeaderAnalysisResult(title: key, description: positiveDesc, isPositive: true))
        } else {
            analysisResults.append(HeaderAnalysisResult(title: key, description: negativeDesc, isPositive: false))
        }
    }
}
