import SwiftUI

struct LinkSanitizerTool: Tool {
    let name = "Link Sanitizer"
    let icon = "link.badge.plus"
    let category = ToolCategory.privacy
    let complexity = ToolComplexity.basic
    let description = "Remove tracking parameters from URLs and expand shortened links safely"
    let requiresAPI = false
    var view: AnyView { AnyView(LinkSanitizerView()) }
}

struct LinkSanitizerView: View {
    @StateObject private var backend = LinkSanitizerBackend()

    var body: some View {
        ToolDetailView(tool: LinkSanitizerTool()) {
            VStack(spacing: 16) {
                inputSection
                if let result = backend.result { resultSection(result) }
                if !backend.errorMessage.isEmpty {
                    Text(backend.errorMessage).foregroundColor(.red).font(.caption).padding(.horizontal)
                }
            }
        }
        .navigationTitle("Link Sanitizer")
    }

    private var inputSection: some View {
        ToolInputSection("Paste URL") {
            VStack(spacing: 10) {
                TextEditor(text: $backend.inputURL)
                    .frame(height: 80)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                HStack {
                    Button("Sanitize") { backend.sanitize() }
                        .buttonStyle(.borderedProminent)
                        .disabled(backend.inputURL.isEmpty)
                    Button("Clear") { backend.clear() }
                        .buttonStyle(.bordered)
                    Button("Paste") {
                        backend.inputURL = UIPasteboard.general.string ?? ""
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    private func resultSection(_ result: SanitizedLink) -> some View {
        VStack(spacing: 12) {
            if !result.removedParams.isEmpty {
                ToolInputSection("Removed Trackers (\(result.removedParams.count))") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(result.removedParams, id: \.self) { param in
                                Text(param)
                                    .font(.system(.caption2, design: .monospaced))
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding()
                }
            }

            ToolInputSection("Clean URL") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.cleaned)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding()
                    HStack {
                        Button {
                            UIPasteboard.general.string = result.cleaned
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        Button("Expand URL") { backend.expandURL() }
                            .buttonStyle(.bordered)
                            .font(.caption)
                            .disabled(backend.isExpanding)
                        if backend.isExpanding { ProgressView().scaleEffect(0.7) }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }

            if let expanded = result.expanded {
                ToolInputSection("Expanded URL") {
                    Text(expanded)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
}
