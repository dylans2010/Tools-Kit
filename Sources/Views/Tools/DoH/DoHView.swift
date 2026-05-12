import SwiftUI

struct DoHTool: Tool, Sendable {
    let name = "DNS over HTTPS"
    let icon = "lock.shield.fill"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Resolve DNS records privately using Cloudflare or Google DoH"
    let requiresAPI = false
    var view: AnyView { AnyView(DoHView()) }
}

struct DoHView: View {
    @StateObject private var backend = DoHBackend()

    var body: some View {
        ToolDetailView(tool: DoHTool()) {
            VStack(spacing: 16) {
                inputSection
                if backend.isLoading {
                    ProgressView("Resolving…")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }
                if !backend.errorMessage.isEmpty {
                    errorCard
                }
                if !backend.records.isEmpty {
                    resultsSection
                }
            }
        }
        .navigationTitle("DNS over HTTPS")
    }

    private var inputSection: some View {
        ToolInputSection("Query") {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    TextField("Domain (e.g. example.com)", text: $backend.domain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                }
                .padding()

                Divider().padding(.leading)

                HStack(spacing: 0) {
                    Picker("Provider", selection: $backend.selectedProvider) {
                        ForEach(DoHProvider.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }

                Divider().padding(.leading)

                Picker("Record Type", selection: $backend.selectedRecordType) {
                    ForEach(DoHRecordType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.menu)
                .padding()

                Divider()

                Button {
                    Task { await backend.lookup() }
                } label: {
                    Label("Resolve", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isLoading || backend.domain.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding()
            }
        }
    }

    private var errorCard: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(backend.errorMessage)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var resultsSection: some View {
        ToolInputSection("Records (\(backend.records.count)) — \(backend.responseTimeMs)ms") {
            ForEach(backend.records) { record in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(record.type)
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(typeColor(record.type).opacity(0.15))
                            .foregroundColor(typeColor(record.type))
                            .cornerRadius(6)
                        Spacer()
                        Text("TTL \(record.ttl)s")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text(record.data)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .padding()
                if record.id != backend.records.last?.id {
                    Divider().padding(.leading)
                }
            }
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "A": return .blue
        case "AAAA": return .indigo
        case "MX": return .orange
        case "TXT": return .green
        case "CNAME": return .purple
        default: return .secondary
        }
    }
}
