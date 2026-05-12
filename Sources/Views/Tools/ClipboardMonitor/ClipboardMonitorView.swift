import SwiftUI

struct ClipboardMonitorTool: Tool, Sendable {
    let name = "Clipboard Monitor"
    let icon = "doc.on.clipboard.fill"
    let category = ToolCategory.privacy
    let complexity = ToolComplexity.basic
    let description = "Detect sensitive patterns in your clipboard locally without sending data externally"
    let requiresAPI = false
    var view: AnyView { AnyView(ClipboardMonitorView()) }
}

struct ClipboardMonitorView: View {
    @StateObject private var backend = ClipboardMonitorBackend()

    var body: some View {
        ToolDetailView(tool: ClipboardMonitorTool()) {
            VStack(spacing: 16) {
                actionSection
                if backend.hasChecked { resultSection }
            }
        }
        .navigationTitle("Clipboard Monitor")
    }

    private var actionSection: some View {
        ToolInputSection("Local Analysis") {
            VStack(spacing: 10) {
                Text("Paste content is analyzed entirely on-device. Nothing is sent externally.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                HStack {
                    Button(action: backend.check) {
                        Label("Check Clipboard", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Clear", action: backend.clear).buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    private var resultSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: backend.isClean ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundColor(backend.isClean ? .green : .red)
                    .font(.title)
                VStack(alignment: .leading) {
                    Text(backend.isClean ? "No Sensitive Data Detected" : "\(backend.findings.count) Issue(s) Found")
                        .font(.headline)
                    Text(backend.isClean ? "Clipboard appears safe" : "Review findings below")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background((backend.isClean ? Color.green : Color.red).opacity(0.08))
            .cornerRadius(12)
            .padding(.horizontal)

            if !backend.findings.isEmpty {
                ToolInputSection("Findings") {
                    ForEach(backend.findings) { finding in
                        findingRow(finding)
                        Divider().padding(.leading)
                    }
                }
            }

            ToolInputSection("Clipboard Preview") {
                Text(backend.rawPreview)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }

    private func findingRow(_ finding: ClipboardFinding) -> some View {
        HStack(spacing: 12) {
            Image(systemName: finding.type.icon)
                .foregroundColor(.red)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(finding.type.rawValue).font(.subheadline.bold())
                Text(finding.description).font(.caption).foregroundColor(.secondary)
                Text(finding.snippet)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
