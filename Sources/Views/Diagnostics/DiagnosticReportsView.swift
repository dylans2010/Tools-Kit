import SwiftUI

struct DiagnosticReportsView: View {
    @StateObject private var reportManager = DiagnosticReportManager.shared
    @State private var showingSaveSheet = false
    @State private var reportTitle = ""
    @State private var selectedReport: DiagnosticReport?
    @State private var showingExportSheet = false

    var body: some View {
        List {
            if !reportManager.currentItems.isEmpty {
                Section("Current Session") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(reportManager.currentItems.count) items recorded")
                                .font(.subheadline.weight(.medium))
                            Text("Tap Save to create a report")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Save") { showingSaveSheet = true }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }

                    ForEach(reportManager.currentItems) { item in
                        reportItemRow(item)
                    }
                }
            }

            Section("Saved Reports") {
                if reportManager.reports.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No saved reports")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Run diagnostics and save results to create reports")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(reportManager.reports) { report in
                        NavigationLink {
                            DiagnosticReportDetailView(report: report)
                        } label: {
                            reportRow(report)
                        }
                    }
                    .onDelete(perform: reportManager.deleteReport)
                }
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !reportManager.currentItems.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") { reportManager.clearCurrentItems() }
                        .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            saveReportSheet
        }
    }

    private func reportItemRow(_ item: DiagnosticReportItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.status.icon)
                .foregroundStyle(item.status.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.toolName)
                    .font(.subheadline.weight(.medium))
                Text(item.details)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func reportRow(_ report: DiagnosticReport) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(report.title)
                .font(.subheadline.weight(.medium))
            HStack(spacing: 12) {
                Label("\(report.passedCount)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Label("\(report.failedCount)", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Label("\(report.warningCount)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .font(.caption2)
            Text(formattedDate(report.createdAt))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var saveReportSheet: some View {
        NavigationStack {
            Form {
                Section("Report Title") {
                    TextField("Enter a title", text: $reportTitle)
                }
                Section("Summary") {
                    let passed = reportManager.currentItems.filter { $0.status == .passed }.count
                    let failed = reportManager.currentItems.filter { $0.status == .failed }.count
                    let warnings = reportManager.currentItems.filter { $0.status == .warning }.count
                    LabeledContent("Total Items") { Text("\(reportManager.currentItems.count)") }
                    LabeledContent("Passed") { Text("\(passed)").foregroundStyle(.green) }
                    LabeledContent("Failed") { Text("\(failed)").foregroundStyle(.red) }
                    LabeledContent("Warnings") { Text("\(warnings)").foregroundStyle(.orange) }
                }
            }
            .navigationTitle("Save Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingSaveSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let title = reportTitle.isEmpty ? "Report \(formattedDate(Date()))" : reportTitle
                        reportManager.saveReport(title: title)
                        reportTitle = ""
                        showingSaveSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DiagnosticReportDetailView: View {
    let report: DiagnosticReport
    @State private var showingShareSheet = false
    @StateObject private var reportManager = DiagnosticReportManager.shared

    var body: some View {
        List {
            Section("Summary") {
                HStack(spacing: 20) {
                    statBadge(count: report.passedCount, label: "Passed", color: .green)
                    statBadge(count: report.failedCount, label: "Failed", color: .red)
                    statBadge(count: report.warningCount, label: "Warnings", color: .orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Device") {
                LabeledContent("Model") { Text(report.deviceModel) }
                LabeledContent("OS") { Text(report.osVersion) }
                LabeledContent("Date") { Text(formattedDate(report.createdAt)) }
            }

            Section("Results (\(report.items.count))") {
                ForEach(report.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: item.status.icon)
                                .foregroundStyle(item.status.color)
                            Text(item.toolName)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(item.category)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                        Text(item.details)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(report.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: reportManager.exportReportAsText(report)) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
