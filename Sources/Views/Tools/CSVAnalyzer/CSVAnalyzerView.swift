import SwiftUI

struct CSVAnalyzerView: View {
    @StateObject private var backend = CSVAnalyzerBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CSV Input").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $backend.csvText)
                        .frame(height: 160)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        .font(.system(.body, design: .monospaced))
                }

                Button(action: backend.analyze) {
                    Label("Analyze CSV", systemImage: "tablecells")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.csvText.isEmpty || backend.isLoading)

                if backend.isLoading {
                    ProgressView("Analyzing…")
                }

                if !backend.errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text(backend.errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                if !backend.columns.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Results — \(backend.columns.first?.values.count ?? 0) rows, \(backend.columns.count) columns")
                            .font(.headline)

                        ForEach(backend.columns) { col in
                            CSVColumnCard(column: col)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("CSV Analyzer")
    }
}

private struct CSVColumnCard: View {
    let column: CSVColumn

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(column.name)
                .font(.headline)
                .foregroundColor(.primary)

            HStack {
                statLabel("Non-empty", value: "\(column.nonEmptyCount)")
                Divider().frame(height: 20)
                if let min = column.min {
                    statLabel("Min", value: formatted(min))
                    Divider().frame(height: 20)
                    statLabel("Max", value: formatted(column.max ?? min))
                    Divider().frame(height: 20)
                    statLabel("Mean", value: formatted(column.mean ?? 0))
                } else {
                    Text("Non-numeric column")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private func statLabel(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.caption).bold()
        }
    }

    private func formatted(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

struct CSVAnalyzerTool: Tool {
    let name = "CSV Analyzer"
    let icon = "tablecells"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Parse and analyze CSV data with per-column statistics"
    let requiresAPI = false
    var view: AnyView { AnyView(CSVAnalyzerView()) }
}
