import SwiftUI

struct TokenInspectorTool: Tool {
    let name = "Token Inspector"
    let icon = "key.horizontal"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Decode and analyze JWTs, API tokens, and bearer tokens locally"
    let requiresAPI = false
    var view: AnyView { AnyView(TokenInspectorView()) }
}

struct TokenInspectorView: View {
    @StateObject private var backend = TokenInspectorBackend()

    var body: some View {
        ToolDetailView(tool: TokenInspectorTool()) {
            VStack(spacing: 16) {
                inputSection
                if !backend.errorMessage.isEmpty {
                    Text(backend.errorMessage).foregroundColor(.red).font(.caption).padding(.horizontal)
                }
                if let analysis = backend.analysis { analysisSection(analysis) }
            }
        }
        .navigationTitle("Token Inspector")
    }

    private var inputSection: some View {
        ToolInputSection("Token") {
            VStack(spacing: 10) {
                TextEditor(text: $backend.token)
                    .frame(height: 100)
                    .font(.system(.caption, design: .monospaced))
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                HStack {
                    Button("Inspect") { backend.inspect() }
                        .buttonStyle(.borderedProminent)
                        .disabled(backend.token.isEmpty)
                    Button("Clear") { backend.clear() }
                        .buttonStyle(.bordered)
                    Button("Paste") {
                        backend.token = UIPasteboard.general.string ?? ""
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    private func analysisSection(_ analysis: TokenAnalysis) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "key.horizontal.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text(analysis.tokenType.rawValue).font(.headline)
                    if analysis.isExpired {
                        Text("⚠️ Expired").font(.caption).foregroundColor(.red)
                    } else if let exp = analysis.expiresAt {
                        Text("Expires: \(exp.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                if let algo = analysis.algorithm {
                    Text(algo).font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            if !analysis.warnings.isEmpty {
                ToolInputSection("⚠️ Warnings") {
                    ForEach(analysis.warnings, id: \.self) { warning in
                        Text(warning).font(.caption).foregroundColor(.orange).padding()
                        Divider()
                    }
                }
            }

            if !analysis.rawHeader.isEmpty {
                ToolInputSection("Header") {
                    ScrollView {
                        Text(analysis.rawHeader)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 120)
                    .padding()
                }
            }

            if !analysis.rawPayload.isEmpty {
                ToolInputSection("Payload") {
                    VStack(alignment: .leading, spacing: 8) {
                        ScrollView {
                            Text(analysis.rawPayload)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .padding()
                        if let iss = analysis.issuer {
                            detailRow("Issuer", value: iss)
                        }
                        if let sub = analysis.subject {
                            detailRow("Subject", value: sub)
                        }
                    }
                }
            }
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption).lineLimit(1)
        }
        .padding(.horizontal)
    }
}
